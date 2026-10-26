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
| `lib/features/courses/application/providers/course_section_build_provider.dart` | État du build par sections (non auto-disposé, SSE) |
| `lib/features/courses/presentation/pages/course_section_builder_page.dart` | Page `/courses/:courseId/build` (générer → valider chaque section) |

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

### Dashboard étudiant — données réelles uniquement (ADRs `Docs/adr/ADR-0001/0002/0003`)

- Identité réelle : nom + email depuis `AuthState` (backend `/auth/me`) ; badge notif et ligne diplôme mockés supprimés ; cloche → état vide honnête (`notifications_empty`) en attendant le module notifications.
- Gate membership : `studentClassMembershipProvider` → `null` = pas de classe = `NoClassNotice` ("contacter l'administration") ; erreur fetch → même notice (fail-safe). Contenu class-dependent (live, cours, devoirs) rendu uniquement si membership réel.
- Live conditionnel : `studentTodayLiveProvider` → `null` = widget masqué (endpoint calendrier du jour non prêt, seam documenté).
- Streak/goal supprimés (widget + modèle + provider + mocks effacés, pas de zéro factice).
- Cours/devoirs : sections conservées (le prof les ajoutera), alimentées par providers vides + états vides (`no_courses`, `no_assignments`) ; compteur inscrits = longueur réelle.
- Entités domaine pures : `student_class_membership.dart`, `today_live_session.dart`, `student_course_progress.dart`, `student_assignment.dart` ; mock `mock_student_dashboard_datasource.dart` supprimé.

### Vérification email + nouveau mot de passe (dossiers déplacés vers `assets/design/ancien/`)

- `VerifyEmailPage` (`/verify-email`, onboarding) : OTP 6 cases + clavier numérique custom. Flux : register → `/verify-email` → `/role-selection`.
  - Widgets : `otp_display_boxes.dart` (états filled/active/empty pilotés par valeur externe), `numeric_keypad.dart` (layout téléphonique standard).
  - Compte à rebours 45s local (pattern `Timer.periodic` UI déjà établi dans `forgot_password_page`) + renvoi + option SMS.
- `ResetPasswordPage` (`/reset-password`, publique) : hero `lock_reset` + badge, jauge 4 segments, checklist 4 règles, badge "Identiques", conseil académique, CTA 3 états (idle → updating → success → `/login`). Flux : forgot `Vérifier le code` → `/reset-password` → `/login`.
  - Widgets : `password_security_meter.dart` (score 0..4), `password_rule_checklist.dart` (labels via `context.tr`, ordre aligné sur `ruleKeys`).
  - Règle : maquettes développées et complètes → dossiers déplacés vers `ancien/`. `smartclass_academic_precision/` restant = DESIGN.md seul (tokens, pas d'écran).

---

## 15. Intégration Backend — Auth & Health (connectés)

> Backend **lecture seule** : aucune modification côté `Backend/`. Seuls les endpoints
> **implémentés** (`contracts/README.md` → ✅) sont connectés. Les autres modules
> (users, groups, courses, exams, …) restent sur mocks (📋 planned).

### Endpoints connectés

| # | Méthode | Path | Auth | Usage frontend |
|---|---------|------|------|----------------|
| 1 | POST | `/api/v1/auth/register` | — | `register_page` (firstName/lastName splittés, rôle `STUDENT`) |
| 2 | POST | `/api/v1/auth/verify-email` | — | `verify_email_page` (retourne tokens → session) |
| 3 | POST | `/api/v1/auth/resend-verification` | — | `verify_email_page` (renvoi) |
| 3b | POST | `/api/v1/auth/check-email` | — | `register_page` : vérif live debounce 600 ms → erreur inline `email_already_exists` (voir ADR-0006 racine) |
| 4 | POST | `/api/v1/auth/login` | — | `login_page` (403 non-vérifié → `/verify-email`) |
| 5 | POST | `/api/v1/auth/refresh` | body | `ApiClient` auto-refresh 401 + retry unique |
| 6 | POST | `/api/v1/auth/forgot-password` | — | `forgot_password_page` (boutons renvoi) |
| 7 | POST | `/api/v1/auth/reset-password` | — | `reset_password_page` (400 → `INVALID_CODE`) |
| 8 | POST | `/api/v1/auth/logout` | — | `AuthNotifier.logout` (best-effort + clear local) |
| 9 | GET | `/api/v1/auth/me` | Bearer | restauration session au démarrage |
| 10 | GET | `/api/v1/auth/profile` | Bearer | `profile_page` (lecture) |
| 11 | PATCH | `/api/v1/auth/profile` | Bearer | `profile_page` (first/last), `completeProfile` |
| 12 | GET | `/health/live` | — | `serverHealthProvider` (tuile Settings) |
| 13 | GET | `/health/ready` | — | idem (latence BDD affichée) |

Conventions : enveloppe `{ data: ... }`, erreurs `{ error: { code, message, details, requestId } }`,
Bearer JWT, rôles backend `TEACHER/STUDENT/ADMIN` ↔ app `teacher/student/admin`
(`UserModel.appRoleToApi`, lowercase à la réception).

### Nouveaux fichiers (frontend uniquement)

```
lib/core/network/
  api_config.dart            # baseUrl (app .env API_BASE_URL, override --dart-define), timeouts, clés storage
  api_client.dart            # Dio + X-Request-Id + Bearer + refresh single-flight + retry 401
  api_exception.dart         # ApiException → Failure (codes stables du contrat)
  token_storage.dart         # SharedPreferences (access + refresh)
  network_providers.dart     # tokenStorage/apiClient/health providers + serverHealthProvider
  health_remote_datasource.dart
lib/core/error/failure_localization.dart  # Failure/code → clé i18n (failureL10n)
lib/features/authentication/
  domain/entities/user_entity.dart
  domain/repositories/auth_repository.dart   # 12 méthodes (dont checkEmailAvailability), throw Failure
  infrastructure/models/{user_model.dart, auth_session.dart}
  infrastructure/datasources/auth_remote_datasource.dart
  infrastructure/repositories/auth_repository_impl.dart  # persiste les tokens
  application/providers/auth_repository_provider.dart   # seam mock ↔ réel
```

### Points d'attention

- `AuthNotifier` (dans `lib/app/app_providers.dart`) orchestre le repository ; restauration
  silencieuse via refresh au démarrage ; `expireSession()` branché sur `ApiClient.onUnauthorized`.
- `AuthState.emailVerified` ajouté : pilote la nav post-login (non-vérifié → `/verify-email`).
- `updateRole` reste **local** (aucun endpoint rôle côté backend) ; email **immutable**
  (PATCH profile : firstName/lastName/birthDate/onboardingCompleted uniquement).
- Boîte "Accès Démo Rapide" supprimée du login (incompatible backend réel) ; boutons
  sociaux → snackbar `feature_coming_soon` (pas d'OAuth au contrat).
- Messages backend bruts jamais affichés : confirmations localisées (`verification_sent`, …),
  erreurs mappées par code (`failureL10n`).
- `checkEmailAvailability` ne touche PAS l'état global (pas de `_emit`) : validation
  d'arrière-plan ; garde anti-réponses obsolètes + timer annulé au dispose.

---

## 16. Module Admin — 7 écrans (maquettes `assets/design/ancien/smartclass_*`, ADR-0004)

> **Données 100 % réelles** (`MockAdminDataSource` supprimé) via
> `AdminRemoteDataSource` + `AdminRepositoryImpl` (endpoints ADMIN-only,
> voir `contracts/admin|users|groups|exams|videoconference.openapi.yaml`).
> Chiffres sans dénominateur server-side (présence, intégrité, taux de
> remplissage, « +32 ») supprimés des écrans — jamais fabriqués.

- Feature `lib/features/admin/` (Clean Architecture stricte) : entités
  (`admin_overview`, `managed_class`, `admin_person`, `timetable`, `fraud_report`
  + `FraudSummary` réel `{unresolved, inProgress, resolvedThisMonth}`),
  `AdminRepository` réel (overview, classes, detail, create/update/delete,
  departments, students/teachers + memberIds, assign/remove, timetable,
  fraudReports paginés cursor + summary + transitions), impl + providers
  (recherche serveur debouncée, curseur fraudes avec « charger plus »,
  classe/semaine de planning sélectionnables).
- Écrans : dashboard (compteurs `GET /admin/overview` + alertes = 2 derniers
  rapports UNTREATED), classes (filtres serveur level/search, mini-stats de
  page, édition via `/admin/classes/new` + `extra`, archivage DELETE avec
  confirmation, planning pré-sélectionné depuis le menu),
  création/édition (`POST/PATCH /groups` : nom, niveau→enum, **filière au
  choix** parmi celles utilisées + saisie libre, capacité, description,
  switches, brouillon=DRAFT, référent optionnel du annuaire enseignants),
  étudiants (`/admin/classes/:id/students` : capacité réelle, assignés/non
  assignés réels, retrait avec confirmation),
  enseignants (`/admin/classes/:id/teachers` : matières/heures réelles,
  matière+heures demandées à la confirmation, retrait),
  planning (`/admin/planning` : sélecteur de classe réelle, semaine
  `weekStart` lundi, timeline filtrée par jour, heures calculées,
  conflits calculés, notes backend verbatim),
  fraudes (`/admin/frauds` : compteurs réels, transitions
  UNTREATED→IN_PROGRESS→CLOSED avec résolution, CLOSED terminal, export
  restant `feature_coming_soon` — pas d'export backend).
- Shell : `_BottomNavBar` par rôle (Tableau/Classes/Planning/Fraudes/Paramètres) ;
  guard `/admin/*` → `/home` si non-admin ; `HomePage` branche admin.
- Règles appliquées : `context.tr()` partout (+ ~30 clés `admin_*`
  FR/EN : filière, référent, transitions, suppressions), `theme.textTheme`
  uniquement, `ApiClient.delete` ajouté, erreurs mappées (`failureL10n`,
  409/422/404), états vides honnêtes (`empty_state`, `admin_no_classes`,
  `admin_no_timetable`).
- Non couvert (pas de backend) : CRUD créneaux timetable (boutons
  `feature_coming_soon`), import CSV, avis académique, export audit,
  appel présentiel, module courses.
- Membership étudiant réel : `GET /groups/mine` → premier membership
  STUDENT (sinon notice « aucune classe ») ; options d'affectation masquées
  si déjà affecté (pages classe + annuaires, avec pré-vérification).

---

## 18. Profil prof, dashboard prof réel, génération de cours IA

- Onboarding : niveau/filière exigés pour les seuls étudiants (`needsStudyInfo`) ;
  profs et admins : établissement uniquement.
- Dashboard prof 100 % réel (`teacherDashboardProvider` : classes via
  `GET /groups/mine` + matières `mySubjects` + prochain créneau via
  timetables, notice « aucune classe » si non affecté ; mocks prof,
  `TeacherStatsRow`, `TeacherClassCard`, `LiveSessionPill` supprimés).
- Création de cours IA branchée sur `POST /api/v1/ai/courses/generate`
  (modes sujet/texte/lien, niveaux concis/équilibré/détaillé qui reshapent
  la consigne, formats résumé/flashcards/carte mentale, matières réelles du
  prof, statut modèle réel, résultat sélectionnable + métadonnées ; PDF binaire en attente
  du pipeline backend — zone d'import honnête en attendant).
- Upload PDF direct : `POST /ai/courses/improve-pdf` (multipart, `file_picker`
  v13), carte fichier avec retrait, modes Sujet/PDF/Lien.
- Génération orientée cours : difficulté (Facile/Moyenne/Difficile),
   longueur Court/Normal/Long, extras (exemples, mermaid, images web,
   recherche web, reflexion),
  3 endpoints dédiés (`from-topic`, `from-url`, `improve-pdf`).
- Progression live : `ApiClient.postStream` + endpoints SSE (`/stream`,
  `/improve-pdf-stream`), carte live (texte temps réel, tokens, écoulé,
  annulation), édition avant validation (Modifier/Valider/Copier).

---

## 17. Rôle — source de vérité backend (fix dashboard par rôle)

> Le backend est la seule source de vérité du rôle (`TEACHER/STUDENT/ADMIN`
> → app `teacher/student/admin`). L'ancien `updateRole` local-only affichait
> un dashboard admin usurpable et était écrasé au login suivant.

- `AuthRemoteDataSource.setMyRole` → `PATCH /api/v1/users/me/role`
  (TEACHER/STUDENT) ; `AuthRepository.setMyRole` persiste la paire de tokens
  fraîche retournée ; `AuthNotifier.updateRole` async (ADMIN → `AuthFailure`
  FORBIDDEN local ; 409 → resync `GET /auth/me`).
- `RoleSelectionPage` : choix étudiant/enseignant uniquement (ADMIN jamais
  auto-assignable, 403 backend) + `_confirm` async avec erreurs localisées.
- `HomePage` : rôle `null/vide` → `_MissingRoleView` (retour `/role-selection`)
  au lieu du dashboard student par défaut ; `AdminDashboardView` si `admin`,
  `TeacherDashboardView` si `teacher`. Doublon `home` du `_BottomNavBar` supprimé.
- Comptes ADMIN provisionnés côté backend uniquement (seed ou
  `PATCH /users/:id/role` par un admin) : `admin@gmail.com`, `admin1@gmail.com`,
  `admin2@gmail.com`.

---

### Fix génération IA + Mes cours réel (v1.6.4)

- **Bug « Erreur du serveur »** : `ai_course_creator_page` envoyait `exExamples`/`exMermaid`/`exWebImages` en clés racines du JSON alors que `generateCourseBodySchema` (Zod `.strict()`, `contracts/ai-assistant.openapi.yaml`) exige `extras: {examples, mermaid, webImages}` → 422. Corrigé : `extras` imbriqué (comme le fait déjà `AiCourseRemoteDataSource._options` pour les endpoints non-stream). `ApiClient.postStream` draine désormais le corps d'erreur streamé (le code backend réel était masqué en `server_error` générique).
- Côté backend : `AI_PERMISSION_MODE=off` + en-tête `X-Unsloth-Events: 1` dans la gateway pour que l'exécution d'outils Unsloth accepte effectivement les tools (sinon 400 + dégradation silencieuse).
- **Mes cours** : zéro mock — `CoursesRemoteDataSource` (`GET /groups/mine`), entité domaine `CourseEntry`, `myCoursesProvider`/`courseFilterProvider` ; cartes = classes réelles (nom, filière/niveau, compteurs membres/enseignants, statut PUBLISHED/DRAFT, rôle). Aucun progrès/leçons fabriqués (module cours backend 📋 planned) ; la recherche au-dessus de la liste affiche `feature_coming_soon`.

### Rendu visuel du cours IA (Markdown → document) (v1.6.5)

- Packages ajoutés : `flutter_markdown` (+ sa dépendance `markdown` en direct pour le builder d'éléments) — justifiés par le rendu réel des cours générés.
- Nouveau widget `courses/presentation/widgets/markdown_course_view.dart` : rendu Markdown sélectionnable stylé Material 3 (H1/H2/H3 colorés, gras, listes, tableaux bordés, citations) ; blocs de code en carte sombre avec étiquette (`figure_mermaid` quand la source commence par `graph|flowchart|mindmap|…`, sinon `code_block`) ; images `![](url)` via `sizedImageBuilder` avec fallback propre.
- `_ResultCard` : le texte brut est remplacé par ce rendu (affichage type document). `_EditorCard` devient stateful avec bascule **Aperçu / Modifier** (clés `ai_preview` / `ai_edit`, FR/EN) : aperçu live du Markdown pendant l'édition, éditeur monospace en mode texte.
- Mermaid resté source copiable (pas de webview dans l'app ; un rendu graphique demanderait `webview_flutter` + serveur mermaid — décision ouverte).

### Rendu Mermaid + quiz pédagogique (v1.6.6)

- **Mermaid** : rendu réel des diagrammes en image PNG via l'encodeur mermaid.ink (`base64Url(code)` → `https://mermaid.ink/img/<b64>?type=png` — aucune donnée sensible : juste la syntaxe du graphe) ; fallback vers la carte de code sombre si hors-ligne.
- **Quiz** : `formatQuizForDisplay` (affichage seulement, le Markdown copié reste brut) — propositions `A) B) C) D)` forcées une par ligne (liste à puces), `Réponse : X` extrait et regroupé dans un bloc `### Corrigé du quiz` (clé `quiz_correction` FR/EN) rendu APRÈS toutes les questions : on ne voit pas les réponses en lisant. Tests unitaires `test/markdown_course_view_test.dart`.

### Mermaid natif via flutter_mermaid (v1.6.7)
- Package `flutter_mermaid: ^0.1.0` : rendu natif des diagrammes (`InteractiveMermaidDiagram`, zoom/pan, offline OK — plus de dépendance à mermaid.ink).
- Types supportés par le renderer : `graph`/`flowchart`, `sequenceDiagram`, `pie`, `gantt`, `timeline` — `mindmap` NON supporté : le prompt backend l'interdit (remplacé par `graph TD` hiérarchique) et `_MermaidFigure` affiche un fallback code brut copiable pour tout bloc non supporté.
- Compatible avec le prompt backend v5 (cours court/normal/complet : plan, intro, parties avec exemples, étude de cas + correction, quiz 5 QCM + correction, conclusion, sous-sections et exercices challenge pour le complet — voir BACKEND_CONTEXT §18).
- Labels UI : niveaux `Cours court` / `Cours normal` / `Cours complet`, formats `Cours structuré` / `Fiches mémo` / `Carte mentale`.

### Cours générés : brouillon → validation → lecture (v1.7.0)

- Backend `GET/POST /api/v1/courses` (`contracts/courses.openapi.yaml`) : sauvegarde en DRAFT, listes `mine` (enseignant) / `published` (tous), lecture `/:id`, `publish`/`unpublish`/`delete` (auteur ou ADMIN).
- Création IA (`ai_course_creator_page`) : bouton **Enregistrer** dans `_ResultCard` (titre dérivé du 1er `# `, garde anti-double-tap, snackbar `course_saved`) ; ré-édition après sauvegarde réarme le bouton (nouveau brouillon, pas de doublon silencieux).
- `CoursesPage` : section **Cours générés** (enseignant : Valider + Supprimer inline, tap → lecteur) ; section **Cours publiés** (étudiants : tap → lecteur).
- `course_reader_page.dart` (`/courses/:courseId`) : `MarkdownCourseView` + actions auteur/admin (Valider/Dépublier/Supprimer), erreurs localisées via `failureL10n`.
- Entité `GeneratedCourse`, datasource dédiée, providers `myGeneratedCoursesProvider` / `publishedCoursesProvider` / `generatedCourseProvider(id)`. Tests `test/generated_course_test.dart`.

### Génération en tâche de fond (v1.7.1)

- `courseGenerationJobProvider` (`StateNotifier`, jamais auto-disposé) : le stream SSE tourne même si l'enseignant quitte la page ; à la fin, **auto-save en DRAFT** (titre dérivé du 1er `# `) + snack `course_ready` avec action « Voir mes brouillons ». Annulation explicite uniquement (`REQUEST_CANCELLED` → idle) ; les erreurs stream remontent via listener (plus de faux « hors-ligne » : timeout stream 10 min + heartbeat `: ping` backend).
- Page créateur refactorée en observatrice : plus de `Timer`/`CancelToken` locaux, `dispose` n'annule rien ; édition locale (`_editedContent`) puis `saveCurrentEdits` (remplace l'ancien brouillon auto-sauvé, pas de doublon) ; `reset()` = « Nouvelle génération ».
- `CoursesPage` (enseignant) : bannière `_RunningJobBanner` (tokens • temps + Annuler) au-dessus des brouillons pendant un run.
- `deriveCourseTitle` extrait dans `application/derive_course_title.dart` (partagé job/page). Tests `test/course_generation_job_test.dart` (faux datasources : auto-save, re-save avec suppression de l'ancien, erreur, idle).
- v1.7.1 — phases visibles : `onPhase` datasource → `phase` du job → carte de progrès (« Analyse du PDF… » pendant l'extraction) ; `sendTimeout` 5 min pour les gros PDF ; `postStream` inchangé par ailleurs.

### Construction par sections validées (v1.9.0)

- **Entrée depuis le plan** : `CourseOutlineEditorCard` gagne `onBuildSections` + `building` (bouton secondaire « Construire section par section », masqué si `generating`/plan vide) → `ai_course_creator_page._startSectionBuild()` : `saveDraft(..., outline: outline)` (le paramètre `outline` vient d'être ajouté au datasource, clé omise si null — schema strict backend) avec **corps = squelette Markdown** (`# titre` + `## chapitres` du plan) → `ref.invalidate(myGeneratedCoursesProvider)` → `context.push('/courses/{id}/build')` (non awaité : une erreur de routage ne doit pas se faire passer pour un échec de sauvegarde ; catches séparés ApiException / générique).
- **Route** `course-section-build` = `/courses/:courseId/build` dans `app_providers.dart`, **hors ShellRoute** (plein écran, comme `ai-create`), positionnée avant le shell pour être matchée en priorité.
- **Couche données** : entity `domain/entities/course_section.dart` (`CourseSectionEntry` avec statuts `pending|generated|validated`, `SectionImageCandidate`, `SectionImageJob` + `CourseBuildCourse` + `CourseBuildData`), datasource `course_section_remote_datasource.dart` (`GET /ai/courses/:id/build`, `POST /ai/courses/sections/validate`, `POST /ai/courses/sections/image/jobs`, `GET /ai/courses/sections/image/jobs/:jobId`, `POST .../image/search`, `POST .../image/apply`). La génération réutilise `AiCourseRemoteDataSource.streamCourse` (SSE, path `/api/v1/ai/courses/sections/generate|regenerate`).
- **Provider** `course_section_build_provider.dart` : `StateNotifierProvider.family<String>` **non auto-disposé** (survit à la navigation comme le job ; un `load()` systématique au retour) ; actions `load` (no-op si un stream est actif, garde `_loadRun`), `generate({sectionKey, regenerate})` (garde VALIDATED sans `regenerate` = 409 backend ; level/difficulté du cours relayés ; `onDelta` → `streamingText`, `onDone` → remplacement de la ligne par la section `saved`, fallback resync), `cancel` (CancelToken, `REQUEST_CANCELLED` silencieux), `validate` (remplace + `invalidate(myGeneratedCoursesProvider)`), `generateSectionImage` (démarre un job ComfyUI, poll `imageJobs[sectionKey]` toutes les 2 s jusqu'à `SUCCEEDED|FAILED`, timeout 7 min, déduplique la relance d'un job actif et propage le 503), `acknowledgeStreamError` ; les jobs vivent dans le notifier non auto-disposé donc continuent quand l'enseignant quitte la page ; pattern job : `error`/`streamError` en assignation directe (tout `copyWith` qui les omet les remet à null = snackbars one-shot).
- **Page** `course_section_builder_page.dart` : AppBar avec badge `validées/total` ; bannière de porte de publication (succès si toutes validées, sinon « X restante(s) ») ; cartes sections (badge `SECTION nn`, chip statut coloré, durée, pills `keyTopics`, `ExpansionTile` → `MarkdownCourseView`, actions par statut : PENDING = Générer, GENERATED = Valider + Régénérer, VALIDATED = Régénérer avec **dialogue de confirmation** qui prévient la perte de validation) ; panneau live pendant le stream (phase mémoire/rédaction, `LinearProgressIndicator`, preview accumulée, bouton Annuler) ; bouton image → dialog `Image.network` au succès, snackbar « bientôt disponible » sur `IMAGE_SERVICE_UNAVAILABLE` ; vues loading/erreur (retry)/vide (`back`) ; erreurs d'action via `failureL10n` (helper local qui intercepte le 503 image avant).
- **Image ComfyUI asynchrone (v1.9.4)** : génération SDXL mesurée **4-5 min** (GTX 1650). Le bouton démarre `POST .../image/jobs` (202) puis le provider poll `GET .../image/jobs/:jobId` toutes les 2 s (timeout 7 min) ; le job et le spinner survivent à la navigation grâce au notifier non auto-disposé, et un retour sur la page retrouve le job actif ou son résultat. Une erreur ComfyUI devient `FAILED` avec `error.code` (`IMAGE_SERVICE_UNAVAILABLE` → snackbar « bientôt disponible ») ; l'image est affichée via `Image.network` sur l'origine `COMFYUI_PUBLIC_URL` du backend (ex. `localhost:8188` sur PC). **Prompts** : le backend distille la section en **UNE scène visuelle concrète sans aucun texte** (anglais format SDXL, réécrite par le LLM local Qwen — ex. « Introduction Scrum » → *two colleagues discussing in front of a blank whiteboard in a workspace* ; négatif = famille du texte en premier ; repli template wordless si le LLM est en échec) avant d'envoyer à ComfyUI ; le champ `prompt` du 200 affiché dans le dialog est donc ce prompt optimisé — aucun changement d'app. Le texte lisible reste les blocs Mermaid du cours.
- **Légende d'explication sous l'image** : le dialog affiche désormais, sous l'image et avant le prompt technique, une section « Explication de l'image » (`ai_build_image_explanation` FR/EN) = description de la section, sinon ses `keyTopics`, **omise si les deux sont vides** (« si besoin »). Piège corrigé au passage : `_imageLoadingKey` était libéré dans le `finally` **après** fermeture du dialog → spinner indéterminé derrière le dialog = `pumpAndSettle` qui n'atterrit jamais ; il est libéré dès que la réponse arrive. +1 widget test (`a generated illustration shows the image explanation caption`, assertion scopée au `AlertDialog` car la description est aussi sur la carte) — **48/48 tests Flutter verts**.
- **i18n** : ~30 clés `ai_build_*` ajoutées aux **deux maps Dart** (`app_localizations.dart` FR/EN) — pas de fichiers arb (source réelle = maps Dart).
- **Piège corrigé** : `ExpansionTile` (ListTile) dans la carte à fond coloré déclenche l'assertion Flutter « ink invisible » → `Material(color: surface)` interne obligatoire.
- Le fix `refinedText`/`revisedText` du dialog de raffinement est **côté backend** (v1.9.0 envoie les deux clés) : `ai_section_refine_dialog.dart` inchangé.
- **Crash « Voir mes brouillons » corrigé (v1.9.2)** : `/courses/ai-create` est **hors ShellRoute** — depuis cette page, `context.push('/courses')` empilait une **2ᵉ page ShellRoute avec la même LocalKey** → assertion Navigator `!keyReservation.contains(key)` au clic. Les 3 raccourcis de `ai_course_creator_page.dart` (snackbar `course_ready`, bouton AppBar `menu_book`, carte résultat `onViewDrafts`) font désormais `context.go('/courses')` : `go` bascule dans le shell existant sans dupliquer la page. `flutter analyze` 0, **48/48 tests verts**. À ne pas confondre avec les `push` de routes **enfant du shell depuis DANS le shell** (ex. détail `/courses/:id`) : go_router les empile dans la branche, pas de doublon — inchangés.
- **⚠️ Leçon (incident)** : un `git checkout -- <fichier>` **sans `git diff` préalable** a écarté **~82 lignes non commitées** de `ai_course_creator_page.dart** (worktree 1709 → 1627 lignes = HEAD + fix go) ; irrécupérable (jamais staged/commité, pas d'historique éditeur). **Toujours `git diff` avant `git checkout`/`git restore`.** Les 63 autres fichiers modifiés du repo sont intacts.
- **Tests** : `test/course_section_build_test.dart` (13 tests : load/erreur de load, stream complet avec remplacement de ligne, état mid-flight (phase+texte), cancel silencieux, erreur stream + acknowledge, garde double-generate, garde VALIDATED sans `regenerate`, validate ×2 avec compteurs, job image démarré+pollé puis résultat réutilisé, job `FAILED` typé, propagation du 503 image) et `test/course_section_builder_page_test.dart` (widget tests : rendu chips+bannière, generate→validate+snack, retry après erreur de load, actions image, 503 « bientôt disponible », dialog d'illustration) ; `_FakeGen.saveDraft` du job test mis à jour (+ param `outline`). **75/75 tests Flutter verts, `flutter analyze` 0 erreur (1 info `dart:html` préexistante).**

*Dernière mise à jour : 2026-10-22*
*Version : 1.9.4*

---

## 19. Lecteur de cours — zéro donnée mockée (v2.0)

### Règle absolue : aucun mock dans Presentation

Le lecteur de cours (`/courses/:courseId`) n'affiche **aucune donnée fabriquée** :
- ❌ Pas de vidéo player factice (play, scrubber, timecode, vitesse, sous-titres)
- ❌ Pas de flashcards en dur (Fiches (4), questions/réponses hardcodées)
- ❌ Pas de points clés IA avec timestamps fictifs (04:12, 12:45, 28:30)
- ❌ Pas de badge "98% fidélité" ni "En direct"
- ❌ Pas de badge "IA Active" dans l'AppBar
- ❌ Pas de "CHAP. 3" en dur
- ✅ Tout provient de l'API via les providers Riverpod

### Structure du lecteur (fichiers < 200 lignes chacun)

```
lib/features/courses/presentation/pages/
  course_reader_page.dart      (~100 lines) : ConsumerWidget, observe generatedCourseProvider
  course_reader_body.dart      (~200 lines) : ConsumerStatefulWidget, meta + sommaire + contenu + sections + actions

lib/features/courses/presentation/widgets/
  course_section_card.dart     (~150 lines) : carte section (statut, générer, régénérer, valider, image)
  course_image_search_dialog.dart (~150 lines) : dialog 5 images web par section
  course_reader_actions.dart   (~100 lines) : barre actions modérateur (Valider/Dépublier/Supprimer/Raffiner)
  course_reader_error.dart     (~50 lines)  : état d'erreur avec retry
```

### Flux de construction par sections (RG4/RG27)

Pour un cours en **DRAFT**, le panneau de construction affiche chacun des 3 états suivants :

| État | Condition | Affichage | Action |
|------|-----------|-----------|--------|
| **Aucun plan** | `initializedFromOutline == false` et `sections.isEmpty` | "Aucun plan n'a encore été généré" | Bouton "Générer directement sans plan" → `/courses/ai-create` |
| **Plan prêt** | `initializedFromOutline == true` et `sections.isEmpty` | "Plan détecté : les chapitres sont prêts à être construits" | Bouton "Construire par sections" → `/courses/:courseId/build` |
| **Sections existantes** | `sections.isNotEmpty` | Panneau avec statut de chaque section (À générer / À valider / Validée) | Générer, Régénérer, Valider, Chercher des images |

Le provider `CourseSectionBuildState` expose `initializedFromOutline` (renseigné par `GET /ai/courses/:id/build` via `CourseBuildData.initializedFromOutline`) pour savoir si un outline existe déjà.

Pour un cours en **DRAFT**, le panneau de construction affiche chaque section avec son statut :

| Statut | Signification | Actions disponibles |
|--------|---------------|---------------------|
| `PENDING` | À générer | Générer |
| `GENERATED` | Généré par l'IA | Valider, Régénérer |
| `VALIDATED` | Validé par l'enseignant | Régénérer (avec confirmation) |

Chaque section a aussi :
- **Chercher des images** : `POST /ai/courses/sections/image/search` (5 candidats web)
- **Insérer une image** : `POST /ai/courses/sections/image/apply`
- **Génération image ComfyUI** : job asynchrone, poll toutes les 2 s (timeout 7 min)

### Mémoire IA (vector recall)

Le backend implémente `SectionMemoryPort` → `PrismaSectionMemoryAdapter` (pgvector) :
- **Remember** : à la validation d'une section, le contenu est indexé en vector (scopé `authorId`)
- **Recall** : lors de la génération d'une section, le modèle reçoit le contexte des cours antérieurs validés de l'auteur
- **UI** : phase `memory` affichée pendant le stream ("Rappel de vos cours antérieurs…"), puis `generating`

### Règles de découpage widgets (PROJECT_CONTEXT §7)

- **Un fichier = une responsabilité** (SRP)
- **Max ~200 lignes par fichier** ; si une page dépasse, la diviser en widgets dédiés
- **Pas de logique métier dans Presentation** : uniquement appel providers + affichage
- **Tous les widgets réutilisables** dans `features/courses/presentation/widgets/`
- **i18n obligatoire** : `context.tr()` partout, aucun texte hardcodé
- **Extensions** : `context.tr()`, `context.showSuccessToast()`, `context.showErrorToast()`, `context.showInfoToast()` depuis `core/extensions/extensions.dart`

### Endpoints utilisés par le lecteur

| Méthode | Path | Usage |
|---------|------|-------|
| GET | `/api/v1/courses/:id` | Contenu complet du cours (Markdown) |
| GET | `/ai/courses/:id/build` | Métadonnées + sections (statuts PENDING/GENERATED/VALIDATED) |
| POST | `/ai/courses/sections/generate` | Générer une section (SSE) |
| POST | `/ai/courses/sections/regenerate` | Régénérer une section (SSE) |
| POST | `/ai/courses/sections/validate` | Valider une section (+ mémoire vectorielle) |
| POST | `/ai/courses/sections/image/search` | 5 images web candidates |
| POST | `/ai/courses/sections/image/jobs` | Démarrer job ComfyUI |
| GET | `/ai/courses/sections/image/jobs/:jobId` | Poller statut job |
| POST | `/ai/courses/sections/image/apply` | Insérer image dans section |

### État des sections et publication

- Un cours DRAFT ne peut **pas** être publié tant qu'une section n'est pas VALIDATED (409 `SECTIONS_NOT_VALIDATED`)
- Une fois toutes les sections VALIDATED, le cours peut être publié
- La validation d'une section insère son contenu dans la mémoire vectorielle de l'auteur

---

## 11. Visioconférence & Live Sessions (Architecture WebRTC, SSE & Tableaux de Bord)

### Principes Fondamentaux & Architecture 3 Tiers
1. **Séparation Stricte des Flux (3-Tier Realtime Architecture - ADR-0009)** :
   - **Flux Média WebRTC** : Transporté exclusivement par le serveur SFU LiveKit auto-hébergé (`livekit_client` 2.11.0). Aucune donnée métier ni chat ne transite par les canaux de signalisation WebRTC.
   - **Mutations & Persistance Métier** : Toutes les commandes de session (démarrage, fin, exclusion, muting, verrou de chat) et la persistance des messages de chat s'effectuent via les API REST sous `/api/v1/videoconference`.
   - **Notifications Temps Réel (Push)** : `GET /videoconference/events` fournit un flux Server-Sent Events persistant, fan-out ciblé sur l'audience de la classe.
2. **Interdiction Formelle du Polling** :
   - Strictement aucun `Timer.periodic` d'interrogation réseau.
   - Le ticking local de 1 seconde dans `StudentImminentLiveCard` et `TeacherImminentLiveCard` est purement visuel (maintien de l'affichage du compte à rebours sans aucun appel HTTP).
   - Les listes et flux de session sont invalidés et rechargés uniquement sur réception d'événements SSE (`session.*`) ou `resync`.
3. **Architecture Propre & Zéro Mock** :
   - `RoomPort` (domaine pur) abstrait complètement la bibliothèque LiveKit.
   - `LiveKitRoomAdapter` (infrastructure) implémente `RoomPort`, gère la publication de pistes, l'adaptive streaming (`dynacast`, `adaptiveStream`), le retournement de caméra sécurisé et le relai des streams de domaine (`connectionStateStream`, `participantJoinedStream`, etc.).
   - `LiveRoomController` (StateNotifier Riverpod) orchestre l'état de la salle, l'activation de l'écran (Wakelock sécurisé), les actions de modération et la déduplication d'événements.

### Écrans & Composants Développés

1. **Lobby (`/videoconference/:sessionId/lobby`)** :
   - Vérification des permissions caméra et micro avant entrée.
   - Toggles d'activation du matériel avec prévisualisation locale.
   - Vue étudiant : état d'attente animé (`WaitingSessionCard`) avec transition automatique vers la salle live dès émission de `session.started` via SSE.
   - Vue enseignant : bouton proéminent "Démarrer la session" créant la salle LiveKit et passant le statut à `IN_PROGRESS`.
2. **Salle Live (`/videoconference/:sessionId/room`)** :
   - Responsive multi-écrans sans aucun mock :
     - **Bureau / Tablette (`WebLiveRoomView`, largeur ≥ 1024px)** : Scène orateur actif principale, filmstrip des autres participants, rail latéral droit avec onglets Chat & Participants, dock de contrôle compact en bas d'écran.
     - **Mobile (`MobileLiveRoomView`, largeur < 1024px)** : Orateur en plein écran, PiP flottant déplaçable avec inertie pour la caméra locale, barre de contrôle ergonomique accessible au pouce, bottom sheets coulissantes pour le chat et les participants.
   - **Gestion de Présence & Modération Hôte** :
     - Liste des participants avec statut muet/parlant et détection de main levée.
     - Actions enseignant : couper le micro d'un participant (`mute`), couper tous les micros (`mute-all`), exclure un participant (`remove` avec interdiction définitive de réémission de token).
     - Déconnexion gérée : options séparées "Quitter le cours" (participant individuel) et "Terminer pour tout le monde" (hôte uniquement).
   - **Partage d'Écran (Host-Only)** :
     - Bouton de partage d'écran affiché uniquement pour l'hôte.
     - Enforced côté serveur via les grants de token LiveKit (`canPublishSources: ['camera', 'microphone']` pour les élèves ; source `screen_share` restreinte au professeur).
   - **Chat Persistant Intégré** :
     - Historique paginé sauvegardé en base de données PostgreSQL (`GET /messages`).
     - Envoi instantané avec déduplication `clientMessageId` (`POST /messages`).
     - Réception temps réel sans rafraîchissement via l'événement SSE `session.chat-message-created`.
     - Bannière informative quand le professeur verrouille le chat (`PATCH /chat-settings`).
3. **Cartes d'Accueil & Compte à Rebours** :
   - `StudentImminentLiveCard` : synchronisation horaire avec compensation de décalage d'horloge serveur (`serverOffset`), badges visuels (`EN DIRECT`, `ACCÈS OUVERT`, `PROCHAIN DIRECT`), compte à rebours dynamique (`Ouverture dans MM:SS` / `Début dans MM:SS`), bouton CTA réactif (désactivé avant ouverture, activé pour rejoindre dès le créneau d'accès).
   - `TeacherImminentLiveCard` : carte dédiée sur le tableau de bord enseignant avec phase courante et boutons d'action contextuels ("Démarrer la session" / "Rejoindre le cours").

### Endpoints Utilisés par le Client

| Méthode | Path | Usage |
|---------|------|-------|
| `GET` | `/api/v1/videoconference/sessions` | Liste filtrée des sessions (`live`, `scheduled`, `past`) |
| `POST` | `/api/v1/videoconference/sessions` | Planification ou démarrage immédiat de session (enseignant) |
| `GET` | `/api/v1/videoconference/sessions/:id` | Détails de la session et statut |
| `PATCH` | `/api/v1/videoconference/sessions/:id` | Modification d'une session planifiée |
| `POST` | `/api/v1/videoconference/sessions/:id/cancel` | Annulation d'une session avec motif |
| `POST` | `/api/v1/videoconference/sessions/:id/start` | Démarrage d'une session planifiée |
| `POST` | `/api/v1/videoconference/sessions/:id/join-token` | Obtention du jeton JWT pour rejoindre la room LiveKit |
| `POST` | `/api/v1/videoconference/sessions/:id/end` | Clôture explicite de la session par l'enseignant |
| `POST` | `/api/v1/videoconference/sessions/:id/leave` | Déclaration de départ du participant |
| `GET` | `/api/v1/videoconference/sessions/:id/participants` | Liste de présence des participants |
| `POST` | `/api/v1/videoconference/sessions/:id/participants/:userId/mute` | Coupure micro d'un participant |
| `POST` | `/api/v1/videoconference/sessions/:id/mute-all` | Coupure collective des micros |
| `POST` | `/api/v1/videoconference/sessions/:id/participants/:userId/remove` | Exclusion d'un participant |
| `GET` | `/api/v1/videoconference/sessions/:id/messages` | Historique des messages de chat |
| `POST` | `/api/v1/videoconference/sessions/:id/messages` | Envoi d'un message de chat |
| `PATCH` | `/api/v1/videoconference/sessions/:id/chat-settings` | Verrouillage/déverrouillage du chat |
| `GET` | `/api/v1/videoconference/me/next-session` | Flux de la session live/imminente pour les widgets dashboard |
| `GET` | `/api/v1/videoconference/events` | Flux SSE continu des événements temps réel |

*Dernière mise à jour : 2026-10-25*
*Version : 2.2.0*
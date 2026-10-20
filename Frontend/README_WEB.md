# SmartClass Web Application — Comprehensive Audit & Implementation Roadmap

> **Audit Date:** October 2026  
> **Source Stitch Project:** `Remix of SmartClass Login Screen` (`projects/17537400567696522497`)  
> **Target Framework:** Flutter Web (`lib/`) + Node.js / Express / Prisma Backend (`Backend/`)

---

## 1. Executive Summary

This document provides a thorough audit of the **SmartClass Web / Desktop version** (`screenWidth >= 1024px`). It compares the screens designed in the Stitch project with the current implementation in the Flutter codebase, clearly separating:

1. **What has a dedicated Web/Desktop layout** vs. what is currently a mobile-scaled view.
2. **What is connected to the real Backend API** vs. what is **"Just UI"** (using mock/dummy data or static placeholders).
3. **What is still missing** to achieve 100% feature parity with the Stitch designs.
4. **The step-by-step roadmap** to build the remaining UI first, and then wire up full end-to-end backend functionality.

---

## 2. Global Status Matrix

| # | Stitch Screen Title | Mobile View | Desktop / Web View | Backend Status | Status Summary |
|---|---------------------|:-----------:|:------------------:|:--------------:|:---------------|
| 1 | **SmartClass - Connexion** | ✅ Implemented | ✅ Dedicated (`WebLoginPage`) | 🟢 Real Backend | Complete & working (`/api/v1/auth/login`) |
| 2 | **SmartClass - Inscription** | ✅ Implemented | ✅ Dedicated (`WebRegisterPage`) | 🟢 Real Backend | Complete & working (`/api/v1/auth/register`) |
| 3 | **SmartClass - Choix du profil** | ✅ Implemented | ✅ Dedicated (`WebRoleSelectionView`) | 🟢 Real Backend | Interactive cards, hover lift, glow ring (`PATCH /api/v1/users/me/role`) |
| 4 | **SmartClass - Configuration du profil** | ✅ Implemented | ✅ Dedicated (`WebProfileSetupView`) | 🟢 Real Backend | Avatar preview, study levels, interest chips (`PUT /api/v1/users/me/profile`) |
| 5 | **SmartClass - Mot de passe oublié & OTP** | ✅ Implemented | ✅ Dedicated (`WebForgotPasswordView`, `WebResetPasswordView`) | 🟢 Real Backend | 2-step card, password security meter, rule checklist |
| 6 | **Tableau de bord Administrateur** | ✅ Implemented | ✅ Dedicated (`WebAdminDashboardPage`) | 🟢 Real Backend | Real stats via `adminOverviewProvider` (`/api/v1/admin/overview`) |
| 7 | **Tableau de bord Enseignant** | ✅ Implemented | ❌ Missing Web View | 🟢 Real Backend | Real backend (`/api/v1/groups/mine`), but renders in single 640px column |
| 8 | **Tableau de bord Étudiant** | ✅ Implemented | ❌ Missing Web View | 🟢 Real Backend | Real backend (`/api/v1/groups/mine`), but renders in single 640px column |
| 9 | **Créer un cours assisté par IA** | ✅ Implemented | ⚠️ Mobile-first | 🟢 Real Backend | Real SSE AI generation streaming (`/api/v1/courses/generate`) |
| 10 | **Édition de cours & Prévisualisation** | ✅ Implemented | ⚠️ Mobile-first | 🟢 Real Backend | Real draft auto-save & publish (`/api/v1/courses/...`) |
| 11 | **Lecteur de Cours & Résumé IA** | ✅ Implemented | ⚠️ Mobile-first | 🟢 Real Backend | Real markdown & mermaid reader (`/api/v1/courses/:id`) |
| 12 | **S'entraîner avec l'IA (Quiz)** | ✅ Implemented | ⚠️ Mobile-first | 🟡 Mock Content | Real responsive quiz UI, uses local generated questions |
| 13 | **Score & Correction IA** | ✅ Implemented | ⚠️ Mobile-first | 🟡 Mock Content | Detailed feedback screen, uses local calculated scores |
| 14 | **Générer mes Révisions** | ✅ Implemented | ⚠️ Mobile-first | 🟡 UI Only | Generation form exists, needs backend persistence |
| 15 | **Fiches de révision & Résumés** | ✅ Implemented | ⚠️ Mobile-first | 🟡 UI Only | Flip card animations working, local state only |
| 16 | **Tuteur IA Interactif (Chat)** | ✅ Implemented | ⚠️ Mobile-first | 🟢 Real Backend | Real chat with Gemini AI stream + web search switch |
| 17 | **Gestion des Classes (Admin)** | ✅ Implemented | ✅ Dedicated (`WebAdminClassesView`) | 🟢 Real Backend | Real class listing, creation, and filtering (`/api/v1/groups`) |
| 18 | **Créer une Nouvelle Classe** | ✅ Implemented | ✅ Modal / Dialog | 🟢 Real Backend | Wired via `AdminRepository` (`POST /api/v1/groups`) |
| 19 | **Suivi de Classe & Détails** | ✅ Implemented | ⚠️ Mobile-first | 🟢 Real Backend | Wired (`/api/v1/groups/:id`, `/members`, `/teachers`), needs widescreen view |
| 20 | **Ajouter des Étudiants** | ✅ Implemented | ✅ Modal / Dialog | 🟢 Real Backend | Real multi-select assignment (`POST /api/v1/groups/:id/members`) |
| 21 | **Affecter des Enseignants** | ✅ Implemented | ✅ Modal / Dialog | 🟢 Real Backend | Real teacher assignment (`POST /api/v1/groups/:id/teachers`) |
| 22 | **Créer un Test Automatique** | ✅ Implemented | ⚠️ Mobile-first | 🟡 UI Only | Exam setup UI exists, backend exam schema pending |
| 23 | **Mode Examen Sécurisé (Anti-fraude)** | ✅ Implemented | ⚠️ Mobile-first | 🟡 UI Only | Camera preview & fullscreen lock UI, needs real proctoring socket |
| 24 | **Rapports de Fraude & Discipline** | ✅ Implemented | ✅ Dedicated (`WebAdminReportsView`) | 🟢 Real Backend | Real fraud incidents (`/api/v1/admin/frauds`) |
| 25 | **Emplois du Temps & Planning** | ✅ Implemented | ⚠️ Partial Web | 🟢 Real Backend | Timetable provider wired (`/api/v1/videoconference/timetable`) |
| 26 | **Planifier une Classe en Direct** | ✅ Implemented | ⚠️ Modal Dialog | 🟢 Real Backend | Wired to videoconference scheduling endpoint |
| 27 | **Groupe & Forum de discussion** | ✅ Implemented | ⚠️ Mobile-first | 🟡 UI Only | Local channel and mock chat messages, needs real WebSocket backend |
| 28 | **Profil & Paramètres** | ✅ Implemented | ⚠️ Mobile-first | 🟢 Real Backend | Profile data, theme toggle, language switcher all work |

---

## 3. Detailed Audit by Module

### Module A: Authentication & Onboarding Flow

#### 1. Login (`/login`)
- **Stitch Reference:** `SmartClass - Connexion` (`d0034c9242a0462a858b80144f410b2a`)
- **Web Layout:** ✅ **Fully Built** (`WebLoginPage` in `lib/features/authentication/presentation/views/web_login_view.dart`).
  - Features: Split-screen hero with animated gradient orbs, university endorsement badges, role switcher tabs, remember me, and quick demo logins.
- **Backend Wiring:** 🟢 **100% Real Backend**.
  - Calls `ref.read(authStateProvider.notifier).login(email, password)`.
  - Authenticates via `POST /api/v1/auth/login`. Returns JWT tokens (stored securely).
  - Routes correctly based on `onboardingCompleted` and `role`.

#### 2. Registration (`/register`)
- **Stitch Reference:** `SmartClass - Inscription` (`de3d6914bdb04f38ac8ddd71ccd18968`)
- **Web Layout:** ✅ **Fully Built** (`WebRegisterPage` in `lib/features/authentication/presentation/views/web_register_view.dart`).
  - Features: Split hero section, real-time password strength meter, role selector, terms acceptance checkbox.
- **Backend Wiring:** 🟢 **100% Real Backend**.
  - Calls `ref.read(authStateProvider.notifier).register(...)` hitting `POST /api/v1/auth/register`.
  - Automatically redirects to `/verify-email`.

#### 3. Email Verification (`/verify-email`)
- **Stitch Reference:** `SmartClass - Mot de passe oublié & Vérification`
- **Web Layout:** ✅ **Fully Built** (`WebVerifyEmailView` in `lib/features/authentication/presentation/views/web_verify_email_view.dart`).
  - Features: Split-screen hero with `WebAuthHeroSection`, 6 keyboard-driven OTP boxes with auto-advance and backspace support, paste detection (Ctrl+V), animated countdown timer with resend button, and `WebControlsBar`.
- **Backend Wiring:** 🟢 **Real Backend** (`POST /api/v1/auth/verify-email`).

#### 4. Role Selection (`/role-selection`)
- **Stitch Reference:** `SmartClass - Choix du profil` (`0cb48d1dcdc54c56b3830a213c46862c`)
- **Web Layout:** ✅ **Fully Built** (`WebRoleSelectionView` in `lib/features/authentication/presentation/views/web_role_selection_view.dart`).
  - Features: Interactive comparison cards for "Étudiant" vs. "Enseignant", smooth hover lift transition, selection ring glow, feature badge pills, and RGPD academic trust banner.
- **Backend Wiring:** 🟢 **Real Backend** (`PATCH /api/v1/users/me/role`).

#### 5. Profile Setup (`/profile-setup`)
- **Stitch Reference:** `SmartClass - Configuration du profil` (`f7563c44789b4befa391a9bb1aa28699`)
- **Web Layout:** ✅ **Fully Built** (`WebProfileSetupView` in `lib/features/authentication/presentation/views/web_profile_setup_view.dart`).
  - Features: Dynamic avatar preview card with user initial badge, academic institution input, study level dropdown, specialty field, interactive interest chips with selection checkmarks, and submit animation.
- **Backend Wiring:** 🟢 **Real Backend** (`PUT /api/v1/users/me/profile`).

#### 6. Forgot Password & Reset (`/forgot-password`, `/reset-password`)
- **Stitch Reference:** `SmartClass - Mot de passe oublié & Vérification` (`8a9ba269f08143048cdf52ccbb4129e4`)
- **Web Layout:** ✅ **Fully Built** (`WebForgotPasswordView`, `WebResetPasswordView`).
  - Features: 2-step card with institutional email dispatch, 4-digit OTP box verification, resend countdown timer, live password strength meter with animated color bars (Weak -> Good -> Excellent), real-time rule checklist, matching indicator, and 3-state animated CTA.
- **Backend Wiring:** 🟢 **Real Backend** (`POST /api/v1/auth/forgot-password`, `POST /api/v1/auth/reset-password`).

---

### Module B: Main Application Shell & Navigation

#### The Desktop Navigation Gap
- In `MainScaffold` (`lib/app/app_providers.dart`):
  ```dart
  final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
  return Scaffold(
    body: child,
    bottomNavigationBar: isDesktop ? null : const _BottomNavBar(),
  );
  ```
- **The Problem:** When `isDesktop` is true, the bottom navigation bar is hidden, but **no desktop navigation rail / sidebar is rendered** for Student and Teacher roles!
- **Admin:** Has its own `WebAdminScaffold` with a full-height sidebar.
- **Student & Teacher:** Are left without a persistent desktop sidebar navigation, forcing them to rely on in-page buttons.
- **Required Fix:** A unified `WebMainScaffold` or role-aware desktop sidebar providing quick access to:
  - *Teacher:* Accueil, Mes Classes, Créateur IA, Emploi du Temps, Profil.
  - *Student:* Accueil, Mes Cours, Tuteur IA, Révisions, Planning, Profil.

---

### Module C: Dashboards

#### 1. Admin Dashboard (`/home` as Admin)
- **Stitch Reference:** `SmartClass - Tableau de bord Administrateur` (`3bfc34e5ed6642e7842756dea1115be4`)
- **Web Layout:** ✅ **Fully Built** (`WebAdminDashboardPage`).
  - Full-width grid, metric cards, quick action links, academic charts.
- **Backend Wiring:** 🟢 **Real Backend**.
  - Fetches real counts from `adminOverviewProvider` (`GET /api/v1/admin/overview`).

#### 2. Teacher Dashboard (`/home` as Teacher)
- **Stitch Reference:** `SmartClass - Tableau de bord Enseignant` (`27ae38c4e84b41e5b111f120b388bb3c`)
- **Web Layout:** ❌ **Mobile layout only**.
  - Currently centers a 640px column with `_TeacherClassCard` and greeting banner.
- **Backend Wiring:** 🟢 **Real Backend**.
  - Real data from `GET /api/v1/groups/mine` and `GET /api/v1/videoconference/timetable`.
- **Missing for Web:**
  - Multi-column widescreen dashboard: Left column with KPI stats & class grid (2-3 columns of class cards), Right column with upcoming sessions, AI creation quick launcher, and recent activity.

#### 3. Student Dashboard (`/home` as Student)
- **Stitch Reference:** `SmartClass - Tableau de bord Étudiant` (`10042dfa54354ea0b1d333547819a42d`)
- **Web Layout:** ❌ **Mobile layout only**.
  - Constrained to 640px vertical stack.
- **Backend Wiring:** 🟢 **Real Backend**.
  - Real enrolled class membership, courses, and timetable.
- **Missing for Web:**
  - Widescreen dashboard: Enrolled class banner across top, 2-column grid with live classes & assignments on left, AI tutor quick prompt & stats on right.

---

### Module D: Classes & Academic Administration

#### 1. Class List & Management (`/admin/classes`)
- **Stitch Reference:** `SmartClass - Gestion des Classes` (`6821eee129d54a48aa5eb7cc2f809e0e`)
- **Web Layout:** ✅ **Dedicated Web View** (`WebAdminClassesView`).
  - Search, level filters, occupancy progress bars, action menus.
- **Backend Wiring:** 🟢 **Real Backend** (`GET /api/v1/groups`).

#### 2. Class Creation Dialog
- **Stitch Reference:** `SmartClass - Créer une Nouvelle Classe` (`be60083b29474a0787d49b85ed1995ce`)
- **Web Layout:** ✅ **Dialog Modal**.
- **Backend Wiring:** 🟢 **Real Backend** (`POST /api/v1/groups`).

#### 3. Class Detail & Roster (`/groups/:groupId`)
- **Stitch Reference:** `SmartClass - Suivi de la Classe 3A & Analyses` (`b799fb41a59946b2b442a7c59f2fa5d0`)
- **Web Layout:** ⚠️ **Mobile-first NestedScrollView**.
  - Functional on desktop, but would benefit from a side-by-side desktop view.
- **Backend Wiring:** 🟢 **Real Backend** (`GET /api/v1/groups/:id`, `/members`, `/teachers`).

#### 4. Assign Students & Teachers Modals
- **Stitch Reference:** `SmartClass - Ajouter des Étudiants` (`aac7b27f...`), `SmartClass - Affecter des Enseignants` (`cf5553ca...`)
- **Web Layout:** ✅ **Dialog Modals** with search and checkboxes.
- **Backend Wiring:** 🟢 **Real Backend** (`POST /api/v1/groups/:id/members`, `POST /api/v1/groups/:id/teachers`).

---

### Module E: Courses & AI Studio

#### 1. AI Course Creator (`/courses/ai-create`)
- **Stitch Reference:** `SmartClass - Créer un cours assisté par IA` (`61f7de5c97d74ddc94669bb659f068bf`)
- **Web Layout:** ⚠️ **Responsive single column**.
- **Backend Wiring:** 🟢 **Real Backend** (Server-Sent Events streaming from `/api/v1/courses/generate`).

#### 2. Course Reader (`/courses/:courseId`)
- **Stitch Reference:** `SmartClass - Lecteur de Cours & Résumé IA` (`5ce9abc104ce46afa036366ee3263d9b`)
- **Web Layout:** ⚠️ **Mobile-first**.
  - Renders markdown, mermaid diagrams, and math formulas properly.
  - On desktop, could incorporate the Stitch floating AI summary panel and table of contents sidebar.
- **Backend Wiring:** 🟢 **Real Backend** (`GET /api/v1/courses/:id`).

#### 3. AI Quiz & Practice (`/ai-quiz`)
- **Stitch Reference:** `SmartClass - S'entraîner avec l'IA` (`d36f3b76...`) & `Score & Correction IA` (`eca77ba0...`)
- **Web Layout:** ⚠️ **Mobile-first**.
- **Backend Wiring:** 🟡 **Local Generated Content / Mock**.
  - Interactive quiz works with score calculation, but doesn't persist results to a dedicated backend evaluation endpoint.

#### 4. Revision Flashcards (`/ai-revision`)
- **Stitch Reference:** `SmartClass - Générer mes Révisions` (`6483d9d7...`) & `Fiches & Résumés` (`28263938...`)
- **Web Layout:** ⚠️ **Mobile-first**.
- **Backend Wiring:** 🟡 **Local State / Mock**.
  - Flashcard flip animation and spaced repetition logic work in UI, but are not stored in PostgreSQL.

---

### Module F: Interactive AI Tutor & Community

#### 1. Interactive AI Tutor (`/ai-assistant`)
- **Stitch Reference:** `SmartClass - Tuteur IA Interactif` (`07906fe145374de184b839701ca0862a`)
- **Web Layout:** ⚠️ **Mobile-first Chat Screen**.
- **Backend Wiring:** 🟢 **Real Backend** (Gemini AI Chat with context & WebSearch streaming).
- **Web Enhancement Needed:** Split layout with chat on left and reference documents / saved notes on right.

#### 2. Collaboration & Forum (`/collaboration`, `/groups`)
- **Stitch Reference:** `SmartClass - Groupe Informatique 3A & Forum` (`3526cad0bee44bdd8064db2b96f544d4`)
- **Web Layout:** ⚠️ **Mobile-first**.
- **Backend Wiring:** 🟡 **Local Mock Data**.
  - Threads and messages are currently in-memory UI; needs a real backend messages/channels endpoint.

---

### Module G: Timetable & Proctoring

#### 1. Timetable & Videoconference (`/videoconference`, `/admin/planning`)
- **Stitch Reference:** `SmartClass - Emplois du Temps & Planning` (`d9d1ed044be741c8b98ce58b720668fa`)
- **Web Layout:** ⚠️ **Mobile Timetable**.
- **Backend Wiring:** 🟢 **Real Backend** (`/api/v1/videoconference/timetable`).

#### 2. Anti-Fraud Secure Exam (`/exams`)
- **Stitch Reference:** `SmartClass - Mode Examen Sécurisé Anti-fraude` (`1e0b7d1544bc443bad5edaff7e55cca7`)
- **Web Layout:** ⚠️ **Mobile-first**.
- **Backend Wiring:** 🟡 **UI Simulation**.
  - Camera preview and anti-cheat indicators work in UI; needs backend event logging socket.

#### 3. Fraud Reports (`/admin/frauds`)
- **Stitch Reference:** `SmartClass - Rapports de Fraude & Discipline` (`d377db20975a423f9b7be267ed98c23e`)
- **Web Layout:** ✅ **Dedicated Web View** (`WebAdminReportsView`).
- **Backend Wiring:** 🟢 **Real Backend** (`GET /api/v1/admin/frauds`).

---

## 4. Priority Roadmap to Make the Web App 100% Functional

### Phase 1: Onboarding & Auth Web Parity (Immediate)
*Goal: Give the entire authentication & setup journey first-class desktop layouts.*

1. **`WebVerifyEmailView` (`/verify-email`):**
   - Create a desktop split view matching `WebLoginPage`.
   - Remove touch numeric keypad on desktop; use auto-focused 6-box input with physical keyboard & clipboard paste.
2. **`WebRoleSelectionView` (`/role-selection`):**
   - Create a widescreen 2-card desktop selector with rich illustrations and role feature comparisons.
3. **`WebProfileSetupView` (`/profile-setup`):**
   - Create a desktop modal/card layout: Left column for avatar upload & quick preview, right column for academic form fields.
4. **`WebForgotPasswordView` (`/forgot-password`):**
   - Create a clean desktop reset card.

### Phase 2: Unified Desktop Navigation & Role Dashboards
*Goal: Provide a persistent desktop shell with sidebar navigation for Teachers and Students.*

1. **`WebMainScaffold`:**
   - Implement a responsive desktop layout featuring a persistent left sidebar with brand logo, role badge, navigation links, and bottom user profile card.
2. **`WebTeacherDashboardView`:**
   - Multi-column widescreen view:
     - Top: Welcome banner & live session alert.
     - Center: Grid of Class Cards (2-3 columns).
     - Right: Quick stats, AI course generation shortcut, and calendar widget.
3. **`WebStudentDashboardView`:**
   - Multi-column view:
     - Enrolled class overview banner.
     - Left column: Enrolled courses & assignments.
     - Right column: AI tutor quick prompt & study streak metrics.

### Phase 3: AI Studio & Reader Desktop Enhancements
1. **Course Reader Desktop View:**
   - Left sidebar: Table of contents / chapters navigation.
   - Center: Rich markdown reading area.
   - Right panel: AI summary, key definitions, and quick questions.
2. **AI Tutor Split View:**
   - Widescreen chat canvas with history sidebar and prompt template library.

### Phase 4: Full Backend Wiring for Remaining Mock Views
1. **Forum & Collaboration:** Connect threads and messages to real database endpoints.
2. **AI Quiz & Flashcards:** Store student quiz results and flashcard decks in PostgreSQL.
3. **Live Exam Proctoring:** Connect fraud violation events to the backend audit log.

---

## 5. Technical Guidelines for New Web Views

1. **Breakpoints:**
   - Always use `context.isDesktop` (`screenWidth >= 1024`) from `lib/core/extensions/extensions.dart`.
2. **Controls & Navigation:**
   - Integrate `WebControlsBar` (`web_language_switcher.dart` + `web_theme_toggle.dart`) in top headers.
3. **Typography & Styling:**
   - Adhere to the Stitch design system (`Inter` font, `#122675` primary blue, `#EEF2FF` soft accents, `#0F172A` neutral dark).
4. **Resilient Data Fetching:**
   - Never let a secondary endpoint error crash the entire page; always provide graceful fallbacks.

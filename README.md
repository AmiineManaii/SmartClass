<div align="center">

# 🎓 SmartClass

### *Next-Generation Intelligent & Collaborative Virtual Learning Platform*

[![Node.js](https://img.shields.io/badge/Node.js-24_LTS-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Express](https://img.shields.io/badge/Express-5.x-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x_Strict-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Flutter](https://img.shields.io/badge/Flutter-3.x_Web_&_Mobile-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.6-blueviolet?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17_pgvector-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Prisma](https://img.shields.io/badge/Prisma-7.x-2D3748?style=for-the-badge&logo=prisma&logoColor=white)](https://www.prisma.io)
[![Design System](https://img.shields.io/badge/Stitch_UI-Academic_Precision-122675?style=for-the-badge)](Frontend/DESIGN.md)
[![Tests](https://img.shields.io/badge/Flutter_Tests-26%2F26_Passing-0F9D78?style=for-the-badge)](Frontend/test/)

<p align="center">
  <a href="#-key-features">Features</a> •
  <a href="#-architecture--project-structure">Architecture</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-api-contracts">Contracts</a> •
  <a href="#-testing--quality">Testing</a> •
  <a href="#-project-roadmap">Roadmap</a>
</p>

</div>

---

## 📖 Overview

**SmartClass** is a unified, privacy-first virtual classroom ecosystem engineered to transform digital education across **Mobile**, **Tablet**, and **Widescreen Web/Desktop**. Combining **interactive videoconferencing**, **real-time student collaboration**, and **local, self-hosted Artificial Intelligence (RAG)**, SmartClass empowers teachers to automate curriculum and course creation while providing students with individualized tutoring, smart lecture summaries, and secure anti-fraud exam simulations.

> **Privacy-First Promise (RG27)**: All pedagogical AI features run on self-hosted models (7B–8B parameter open weights) using `pgvector` for Retrieval-Augmented Generation (RAG). Student and course data never leave your infrastructure.

---

## ✨ Key Features & Widescreen Web Experience

<table>
  <tr>
    <td width="50%">
      <h3>🤖 AI Course Creator & Pedagogical Studio</h3>
      <ul>
        <li><b>Widescreen Course Creator Studio (UC1):</b> Responsive 2-column workspace (Left: configuration studio `flex: 48`; Right: live canvas `flex: 52`) with the <i>Moteur Pédagogique IA v3.2</i>.</li>
        <li><b>Prompt Recommendation Chips:</b> One-click insertion for <i>"Plan détaillé"</i>, <i>"Quiz interactif inclus"</i>, <i>"Exercices pratiques"</i>, <i>"Études de cas"</i>, and <i>"Schémas Mermaid"</i>.</li>
        <li><b>Academic Quick-Start Templates:</b> Pre-configured templates for <i>Bases de données SQL</i>, <i>Algèbre linéaire</i>, and <i>Théorie des graphes</i> with difficulty tags.</li>
        <li><b>Floating AI Assistant Action Bar:</b> Quick refinement actions (<i>"Reformuler"</i>, <i>"Ajouter des exemples"</i>, <i>"Simplifier"</i>, <i>"Générer un QCM"</i>).</li>
      </ul>
    </td>
    <td width="50%">
      <h3>💡 Interactive AI Tutor & Course Reader</h3>
      <ul>
        <li><b>Conversational AI Tutor (UC2):</b> 2-column chat workspace (`flex: 7` conversation, `flex: 5` reference rail) with mathematical formula blocks (`\dim(E) = \dim(\text{Ker}(f)) + \text{rg}(f)`), step titles, voice playback, and quick prompt chips.</li>
        <li><b>Interactive Course Reader (UC4):</b> Chalkboard video banner with lecturer PIP avatar, scrubber, and <b>clickable AI timestamp markers</b> (`04:12`, `12:45`, `28:30`, `39:15`) that jump directly to sections.</li>
        <li><b>AI Companion Side-Rail:</b> Segmented workspace tabs for <i>Résumé IA</i> (98% fidelity guarantee, golden rules), <i>Fiches Mémo</i> (animated flip cards), and <i>Notes Personnelles</i>.</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🛡️ Secure Anti-Fraud Exam Room & AI Scoring</h3>
      <ul>
        <li><b>Proctoring Telemetry Lock (UC9):</b> Real-time hardware telemetry bar monitoring active webcam, microphone input, browser tab focus, and full-screen enforcement.</li>
        <li><b>Urgent Countdown & Progress Rail:</b> Dynamic countdown timer with urgency alerts (< 15 mins) and segmented question tracker.</li>
        <li><b>AI Pedagogical Score Diagnostic:</b> Custom radial score ring (`16 / 20`), honors mention (<i>Très Bien</i>), cohort benchmark (`+3.2 pts vs promo`), and automated review recommendations.</li>
        <li><b>Interactive Question Breakdown:</b> Category filters (<i>Toutes</i>, <i>Erreurs</i>, <i>Réussies</i>) with detailed explanations.</li>
      </ul>
    </td>
    <td width="50%">
      <h3>🖥️ Desktop Shell & Onboarding Suite</h3>
      <ul>
        <li><b>Persistent Navigation Shell:</b> 260px navy sidebar (`#2D3E8C`), quick role switcher, active capsule states, and user session card.</li>
        <li><b>Role Dashboards:</b> Widescreen layouts for Student (Salma) and Teacher (Amine) with motivation cards, timetable rails, and live class alerts.</li>
        <li><b>Complete Onboarding Views:</b> Split-screen login, register, 6-box OTP verification with auto-paste (Ctrl+V), interactive role cards with hover lift & glow ring, and 2-step password recovery with live entropy meter.</li>
      </ul>
    </td>
  </tr>
</table>

---

## 👥 Personas & Roles

| Persona | Role | Core Objectives & Value Proposition |
|---|---|---|
| **👨‍🏫 Amine** | **Teacher** | Streamlines syllabus prep in the 2-column AI Course Studio, generates exercises in seconds, plans virtual classes, and tracks cohort progress. |
| **🎓 Salma** | **Student** | Accesses centralized coursework, navigates lectures via AI video timestamps, consults the interactive 2-column AI Tutor, and takes secure proctored exams. |
| **🛡️ Karim** | **Admin** | Manages institutions and classes, monitors exam proctoring audit trails, enforces GDPR compliance, and oversees infrastructure reliability. |

---

## 🏗️ Architecture & Project Structure

SmartClass is structured as a **clean monorepo** adhering strictly to **Domain-Driven Design (DDD)** and **Hexagonal (Ports & Adapters) Architecture** across both frontend and backend.

```
SmartClass/
├── Backend/                 # Node.js 24 LTS REST API & Domain Core
│   ├── prisma/              # PostgreSQL 17 + pgvector schema & migrations
│   ├── src/
│   │   ├── config/          # Fail-fast Zod environment validation
│   │   ├── modules/         # Bounded Contexts (Auth, Users, Courses, Groups, Admin...)
│   │   ├── shared/          # Shared Kernel (AppError, logger, middlewares, pagination)
│   │   ├── app.ts           # Express 5 application factory
│   │   └── main.ts          # Server bootstrap with graceful shutdown & banner
│   ├── tests/               # In-memory Vitest unit tests & Supertest integration tests
│   └── Dockerfile           # Multi-stage container (dev, build, production)
│
├── Frontend/                # Flutter Cross-Platform Client (Web, Desktop, Mobile, Tablet)
│   ├── lib/
│   │   ├── app/             # App entrypoint, GoRouter configuration & Riverpod providers
│   │   ├── core/            # Design system, theme, typography, WebMainScaffold, ResponsiveLayout
│   │   └── features/        # Feature modules (auth, home, courses, ai_assistant, exams, groups, admin)
│   ├── assets/              # SVG vectors, typography, illustration packs
│   └── test/                # Unit & Widget test suite (web_views_test.dart, smart_loader_test.dart)
│
├── contracts/               # Hand-written OpenAPI 3.1 specifications (Contract-First)
│   ├── common.yaml          # Shared schemas (errors, pagination, security)
│   └── health.openapi.yaml  # Health module specification
│
├── Docs/                    # Project framing specifications & architecture plans
│   ├── SmartClass_Cadrage.html  # Complete functional & technical specifications
│   └── ANTIGRAVITY_INIT_PROMPT.md
│
├── docker-compose.yml       # Production-ready container orchestration
└── .gitignore               # Unified monorepo ignore rules
```

---

## 🚀 Quick Start

### Prerequisites
- [Docker & Docker Compose](https://www.docker.com/) (recommended)
- [Node.js 24 LTS](https://nodejs.org/) & [npm 10+](https://www.npmjs.com/)
- [Flutter SDK 3.x](https://flutter.dev/) (for frontend development)

---

### Option 1 — Start Full Stack via Docker (Recommended)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/AmiineManaii/SmartClass.git
   cd SmartClass
   ```

2. **Configure Environment**:
   ```bash
   cp Backend/.env.example Backend/.env
   ```

3. **Start the database & backend services**:
   ```bash
   cd Backend
   docker compose up -d --build
   ```

4. **Verify container status**:
   ```bash
   docker compose ps
   # Both smartclass-api and smartclass-db should report (healthy)
   ```

5. **Test the live API**:
   ```bash
   # Liveness check
   curl http://localhost:3000/health/live

   # Readiness check (verifies PostgreSQL 17 + pgvector connection)
   curl http://localhost:3000/health/ready
   ```

---

### Option 2 — Running the Backend Locally

```bash
cd Backend
npm install
npm run db:migrate    # Runs pending Prisma migrations
npm run dev           # Starts development server with hot-reload (tsx watch)
```

Upon boot, the server tests database latency and displays our signature Spring Boot-style startup banner:

```
  ____  __  __    _    ____ _____ ____ _        _    ____ ____  
 / ___||  \/  |  / \  |  _ \_   _/ ___| |      / \  / ___/ ___| 
 \___ \| |\/| | / _ \ | |_) || || |   | |     / _ \ \___ \___ \ 
  ___) | |  | |/ ___ \|  _ < | || |___| |___ / ___ \ ___) |__) |
 |____/|_|  |_/_/   \_\_| \_\|_| \____|_____/_/   \_\____/____/ 
 :: SmartClass Backend API ::                      (v0.1.0)

┌────────────────────────────────────────────────────────────────────────┐
  ● SERVER LIVE & RUNNING
├────────────────────────────────────────────────────────────────────────┤
  • Database    : CONNECTED (PostgreSQL 17 + pgvector • 12ms)
  • Environment : development
  • Local Port  : 3000
  • Base URL    : http://localhost:3000/api/v1
  • Liveness    : http://localhost:3000/health/live
  • Readiness   : http://localhost:3000/health/ready
└────────────────────────────────────────────────────────────────────────┘
```

---

### Option 3 — Running the Flutter Client

```bash
cd Frontend
flutter pub get

# Run on Google Chrome (Recommended for testing widescreen Web views)
flutter run -d chrome

# Or run on Windows Desktop
flutter run -d windows
```

> **Demo 1-Click Access**: On the login screen, use the quick demo box to sign in directly as **🎓 Étudiant (Salma)** or **👨‍🏫 Enseignant (Amine)** without credentials.

---

## 📡 API Contracts & Documentation

SmartClass adheres to a **Contract-First API design pattern**. The Flutter client integrates directly against versioned OpenAPI specifications:

| Contract | Path | Description |
|---|---|---|
| 📋 **Index & Guidelines** | [`contracts/README.md`](contracts/README.md) | Contract standards, formatting conventions, and versioning rules |
| 🧩 **Common Components** | [`contracts/common.yaml`](contracts/common.yaml) | RFC 7807 error envelopes, cursor & offset pagination metadata, `bearerAuth` |
| 🩺 **Health Module** | [`contracts/health.openapi.yaml`](contracts/health.openapi.yaml) | `/health/live` and `/health/ready` (including 503 DB fallback specifications) |

---

## 🧪 Testing & Quality Assurance

Our monorepo enforces strict type safety and quality standards across both frontend and backend:

### Backend Testing (TypeScript / Vitest / Supertest)
```bash
cd Backend
npm run lint          # ESLint flat config with TypeScript rules
npm run typecheck     # Strict TypeScript compiler verification (tsc --noEmit)
npm test              # Full Vitest unit & Supertest integration suite
```

### Frontend Testing (Flutter / Dart)
```bash
cd Frontend
flutter analyze lib/  # Verified with 0 issues found
flutter test          # Verified with 26/26 tests passing
```

The frontend automated suite covers:
- **Responsive Layouts**: Breakpoint adaptation between mobile, tablet, and desktop (`>= 1024px`).
- **Widescreen Views**: Authentication, Onboarding, Role Selection, Profile Setup, Password Recovery, Web Scaffolds, Dashboards.
- **AI Pedagogical Views**: 2-column AI Course Creator Studio, AI Assistant Chat Rail, Course Reader with video timestamps.
- **Secure Assessments**: Anti-fraud proctoring telemetry banner, countdown timer, question tracker, and AI score diagnostics.

---

## 🗺️ Project Roadmap

- [x] **Sprint 0 — Foundation & Infrastructure**: Monorepo layout, Docker orchestration, PostgreSQL 17 + `pgvector`, Clean Architecture health module, OpenAPI contracts, baseline test suites.
- [x] **Sprint 1 — Auth & Onboarding Web Suite**: Multi-role JWT authentication, split-screen desktop login/register, 6-box OTP with auto-paste, interactive role selection with hover elevation, profile setup with live avatar preview, and 2-step password recovery with live entropy meter.
- [x] **Sprint 2 — Course Studio & Interactive Reader**:
  - Widescreen 2-column AI Course Creator Studio (`AiCourseCreatorPage`) with prompt recommendation chips, quick templates canvas, and floating AI refinement bar.
  - Interactive Course Reader (`CourseReaderPage`) with chalkboard video banner, lecturer PIP, clickable AI timestamp navigation, and 3-tab AI companion rail (*Résumé IA*, *Fiches*, *Notes*).
- [x] **Sprint 3 — AI Assistant & Tutor**:
  - Desktop 2-column AI Assistant (`AiAssistantPage`) with connected course selector, mathematical LaTeX formula blocks, precision indicator, and contextual cheat-sheet rail.
- [x] **Sprint 4 — Secure Anti-Fraud Proctoring & AI Score Diagnostics**:
  - Secure Exam Room (`SecureExamPage`) with real-time proctoring telemetry (webcam, audio, tab focus lock, fullscreen enforcement), countdown timer, and segmented tracker.
  - AI Pedagogical Score & Correction View (`ExamAiScorePage`) with custom radial score ring (`16 / 20`), cohort benchmark (`+3.2 pts`), mini KPI cards, diagnostic synthesis, and interactive category filters.
- [ ] **Sprint 5 — Collaborative Spaces & Live Videoconference**:
  - Student & Class Community Forum (Stitch screen `3526cad0bee44bdd8064db2b96f544d4`) with channels, pinned announcements, upvoting, and interactive polls.
  - Virtual Classroom Live Planner (Stitch screen `cbd433ad530b4ebc9674dcbc3be8a2b5`) with WebRTC/LiveKit room integration and participant roster.
- [ ] **Sprint 6 — Academic Analytics & Advanced RAG**:
  - Class tracking and retention analytics (Stitch screen `b799fb41a59946b2b442a7c59f2fa5d0`).
  - Persistent quiz attempt tracking and vector-indexed student knowledge graphs.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

<div align="center">
  <sub>Built with ❤️ for the future of intelligent education.</sub>
</div>


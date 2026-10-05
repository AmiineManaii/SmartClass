<div align="center">

# 🎓 SmartClass

### *Next-Generation Intelligent & Collaborative Virtual Learning Platform*

[![Node.js](https://img.shields.io/badge/Node.js-24_LTS-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Express](https://img.shields.io/badge/Express-5.x-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x_Strict-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17_pgvector-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Prisma](https://img.shields.io/badge/Prisma-7.x-2D3748?style=for-the-badge&logo=prisma&logoColor=white)](https://www.prisma.io)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.1_Contracts-6BA539?style=for-the-badge&logo=openapiinitiative&logoColor=white)](contracts/)

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

**SmartClass** is a unified, privacy-first virtual classroom ecosystem engineered to transform digital education. By combining **interactive videoconferencing**, **real-time student collaboration**, and **local, self-hosted Artificial Intelligence (RAG)**, SmartClass empowers teachers to automate content generation while providing students with individualized tutoring and secure exam simulations.

> **Privacy-First Promise (RG27)**: All pedagogical AI features run on self-hosted models (7B–8B parameter open weights) using `pgvector` for Retrieval-Augmented Generation (RAG). Student and course data never leave your infrastructure.

---

## ✨ Key Features

<table>
  <tr>
    <td width="50%">
      <h3>🤖 AI Pedagogical Studio</h3>
      <ul>
        <li><b>Course Creation Assistant (UC1):</b> Extracts and structures legacy PDFs/documents into interactive modules with teacher validation.</li>
        <li><b>Adaptive Tutoring & Quizzes (UC2):</b> Instant individualized quizzes with progressive hints and grounded explanations.</li>
        <li><b>Audio & Replay Intelligence (UC4):</b> Automated lecture transcription (Whisper) and synthesized key-takeaway summaries.</li>
      </ul>
    </td>
    <td width="50%">
      <h3>🎥 Real-Time Interactive Classroom</h3>
      <ul>
        <li><b>Videoconference Hub (UC3):</b> Integrated HD classroom sessions with host management, screen sharing, and live breakout rooms.</li>
        <li><b>Collaborative Whiteboard & Code (UC5):</b> Multi-cursor shared canvases and live code execution environments for group assignments.</li>
        <li><b>Class Groups & Permissions (UC6):</b> Granular role-based governance for schools, courses, and student cohorts.</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🛡️ Secure Exam Proctoring</h3>
      <ul>
        <li><b>Multi-Chapter Exam Simulation (UC9):</b> Automated timed assessments with randomized question banks.</li>
        <li><b>AI Integrity Shield:</b> Edge-based webcam presence detection, browser lockdown, tab-switch monitoring, and post-exam audit reports.</li>
      </ul>
    </td>
    <td width="50%">
      <h3>📊 Analytics & Performance Tracking</h3>
      <ul>
        <li><b>Teacher Insights (UC7):</b> Cohort heatmaps, knowledge retention matrices, and struggle-point identification.</li>
        <li><b>Student Learning Journey:</b> Gamified progress tracker, revision recommendations, and personalized mastery dashboards.</li>
      </ul>
    </td>
  </tr>
</table>

---

## 👥 Personas & Roles

| Persona | Role | Core Objectives & Value Proposition |
|---|---|---|
| **👨‍🏫 Amine** | **Teacher** | Streamlines syllabus prep, generates exercises from PDFs in seconds, animates distance lectures, and tracks class mastery without tool fragmentation. |
| **🎓 Salma** | **Student** | Accesses centralized coursework, replays recorded classes with AI smart summaries, trains on adaptive practice exams, and collaborates in real-time. |
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
│   │   ├── modules/         # Bounded Contexts (Health, Auth, Courses, etc.)
│   │   │   └── health/      # Reference module (Domain, Application, Infra, Presentation)
│   │   ├── shared/          # Shared Kernel (AppError, logger, middlewares, pagination)
│   │   ├── app.ts           # Express 5 application factory
│   │   └── main.ts          # Server bootstrap with graceful shutdown & banner
│   ├── tests/               # In-memory Vitest unit tests & Supertest integration tests
│   └── Dockerfile           # Multi-stage container (dev, build, production)
│
├── Frontend/                # Flutter Cross-Platform Application (Mobile, Tablet, Web)
│   ├── lib/
│   │   ├── core/            # Design system, theme, network, typography, widgets
│   │   └── features/        # Feature modules (Auth, Home, AI Studio, Exams, Groups...)
│   └── assets/              # SVG vectors, typography, illustration packs
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

### Option 3 — Running the Flutter Frontend

```bash
cd Frontend
flutter pub get
flutter run -d chrome     # Or connect an Android / iOS device
```

---

## 📡 API Contracts & Documentation

SmartClass adheres to a **Contract-First API design pattern**. The Flutter client integrates directly against versioned OpenAPI specifications rather than inspecting backend source code:

| Contract | Path | Description |
|---|---|---|
| 📋 **Index & Guidelines** | [`contracts/README.md`](contracts/README.md) | Contract standards, formatting conventions, and versioning rules |
| 🧩 **Common Components** | [`contracts/common.yaml`](contracts/common.yaml) | RFC 7807 error envelopes, cursor & offset pagination metadata, `bearerAuth` |
| 🩺 **Health Module** | [`contracts/health.openapi.yaml`](contracts/health.openapi.yaml) | `/health/live` and `/health/ready` (including 503 DB fallback specifications) |

---

## 🧪 Testing & Quality Assurance

Our codebase enforces strict type safety and quality standards before every commit:

```bash
# In Backend/ directory:
npm run lint          # ESLint flat config with TypeScript rules
npm run typecheck     # Strict TypeScript compiler verification (tsc --noEmit)
npm test              # Full Vitest unit & Supertest integration suite
```

- **Unit Tests**: Pure in-memory tests verifying Domain Ports, Use Cases, Pagination, and Error Mappers.
- **Integration Tests**: End-to-end Supertest suites asserting HTTP envelopes, Request ID propagation, rate limiting, and database failover recovery.

---

## 🗺️ Project Roadmap

- [x] **Sprint 0 — Foundation & Infrastructure**: Monorepo layout, Docker orchestration, PostgreSQL 17 + `pgvector`, Clean Architecture health module, OpenAPI contracts, test suites.
- [ ] **Sprint 1 — Auth & Cohorts**: Multi-role JWT authentication (Argon2id, rotating refresh tokens), onboarding flow, class-group management (UC8, UC6).
- [ ] **Sprint 2 — Course Studio**: PDF extraction, teacher curriculum builder, local LLM course structuring (UC1).
- [ ] **Sprint 3 — Videoconference & Replay**: WebRTC/LiveKit live sessions, Whisper transcription, automatic lecture summaries (UC3, UC4).
- [ ] **Sprint 4 — Personalized RAG Studio**: Vector similarity retrieval over course notes, individualized practice exams (UC2, UC10).
- [ ] **Sprint 5 — Collaborative Workspaces & Assessments**: Live shared whiteboard, shared code runner, proctored exam engine v1 (UC5, UC9).
- [ ] **Sprint 6 — Anti-Fraud Proctoring & Analytics**: Edge vision proctoring, integrity anomaly reporting, institutional analytics (UC7, UC9 v2).

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

<div align="center">
  <sub>Built with ❤️ for the future of intelligent education.</sub>
</div>

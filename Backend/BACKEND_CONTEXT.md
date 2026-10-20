# SmartClass Backend — Contexte Technique du Projet

> **Ce fichier est la mémoire technique du backend.**
> - À lire **EN ENTIER avant toute tâche** (nouvelle feature, bugfix, refactor).
> - À mettre à jour **APRÈS chaque tâche** (§16 Statut, §18 Journal, §1 si un package est ajouté, **et le contrat OpenAPI de tout endpoint touché**, voir §5.1).
> - C'est le pendant de `PROJECT_CONTEXT.md` (Flutter) : Clean Architecture stricte, conventions obligatoires, interdits explicites.

## 0. Sources de vérité (ordre de priorité en cas de conflit)

### Organisation du dépôt (monorepo)

```
smartclass/            # racine du monorepo = workspace de l'IDE
├── front/             # app Flutter
├── backend/           # CE projet (BACKEND_CONTEXT.md est ici)
├── docs/              # SmartClass_Cadrage.html, FRONTEND_CONTEXT.md
└── contracts/         # contrats OpenAPI de l'API (voir §5.1)
```
*(adapter les noms si les dossiers réels diffèrent ; tous les chemins ci-dessous sont relatifs à `backend/`.)*

| # | Source | Contenu |
|---|--------|---------|
| 1 | `../docs/SmartClass_Cadrage.html` | **Fonctionnel** : personas, use cases (UC1-UC10), règles métier (RG), modèle de données, flux, sprints |
| 2 | `../contracts/*.openapi.yaml` | **Contrat API** : ce que chaque endpoint exige et renvoie (lu par le front) |
| 3 | `../docs/FRONTEND_CONTEXT.md` (optionnel) | **Contexte client** : ce que l'app Flutter attend |
| 4 | `BACKEND_CONTEXT.md` (ce fichier) | **Technique** : stack, architecture, conventions, sécurité |

On n'invente **jamais** une règle métier. Cadrage muet ou ambigu → on le note en §18 (« Décisions ouvertes ») et on demande.

---

## 1. Stack & décisions

### 1.1 Décisions

| Domaine | Choix | Pourquoi | Quand |
|---------|-------|----------|-------|
| Runtime | **Node.js 24 LTS** + **TypeScript strict** (ESM) | Concurrence (visio/examens), typage fort | Init |
| HTTP | **Express 5** | Imposé ; erreurs async gérées nativement | Init |
| Base de données | **PostgreSQL 17** (image `pgvector/pgvector:pg17`) | Cadrage ; pgvector prêt pour le RAG | Init |
| ORM | **Prisma** (dernière stable) | Schéma déclaratif, migrations fiables, types générés | Init |
| Validation | **Zod** | Validation + types depuis une seule source | Init |
| Logs | **pino** + **pino-http** | JSON structuré, rapide, redaction des secrets | Init |
| Sécurité HTTP | **helmet** + **cors** | Standards | Init |
| Rate limiting | **express-rate-limit** (store mémoire pour l'instant) | Simple, reconnu | Init |
| Tests | **Vitest** + **Supertest** | Rapide, ESM natif | Init |
| Qualité | **ESLint** + **Prettier** | Standard | Init |
| Conteneurs | **Docker** multi-stage + **docker-compose** (`api` + `db`) | Environnement reproductible | Init |
| Auth | JWT access court + refresh token rotatif, hash argon2id | Standard mobile | **Sprint 1** — packages à confirmer à ce moment |
| Redis | Rate limit partagé, files de jobs | Utile dès 2+ instances ou jobs async | Plus tard |
| Contrats API | **OpenAPI 3.1 YAML écrits à la main** dans `../contracts/`, approche **contract-first** (§5.1) | Le front lit le contrat au lieu de fouiller le backend | **Init** (dossier + règles) |
| Génération/validation auto des contrats (depuis Zod, lint en CI, client Dart) | À décider | Quand Flutter branche Dio/Retrofit | Plus tard |
| Stockage objets | Port `StoragePort` S3-compatible. **MinIO est archivé** (images Docker retirées) → moteur à choisir (SeaweedFS / Garage / RustFS / S3 managé) | | **Sprint 2** |
| IA / RAG | Port `AiGatewayPort` → service IA **auto-hébergé** (RG27 : aucune API LLM tierce). v1.6.0 : gateway OpenAI-compatible (Unsloth Desktop) + génération de cours live ; RAG pgvector + upload PDF en attente (modèle d'embedding, `multer`, parseur PDF) | Sprint 2/4 |
| Temps réel | Socket.IO ou SSE (le front interdit le polling) | | Sprint 3+ |

> **Écart assumé vs cadrage** : le cadrage parle d'API Gateway + services métier. On livre un **monolithe modulaire** : chaque « service » du cadrage = un module avec sa propre Clean Architecture et une façade publique → extractible plus tard. Seul le Service IA reste externe (GPU, RG27).
> **Écart assumé** : timestamps en `TIMESTAMPTZ` partout (le cadrage dit `TIMESTAMP`).

### 1.2 Politique des packages (OBLIGATOIRE)

- On installe **uniquement** ce que la tâche en cours exige. Un package = une justification en une ligne.
- Package non listé ci-dessous → **demander avant de l'ajouter**, puis le consigner ici.
- Pas de dotenv : Docker injecte l'env (`env_file`), Node sait charger un fichier avec `--env-file` en local.

**Installés à l'init** (à tenir à jour)

| Package | Rôle |
|---------|------|
| `express` | Serveur HTTP |
| `zod` | Validation env + requêtes |
| `@prisma/client` + `prisma` (+ adapter/driver PostgreSQL si la version de Prisma l'exige) | Accès DB + migrations |
| `pino`, `pino-http` | Logs |
| `helmet`, `cors` | Sécurité HTTP |
| `express-rate-limit` | Anti-abus |
| `typescript`, `tsx`, `@types/node`, `@types/express`, `@types/cors` | Compilation / dev avec hot reload |
| `vitest`, `supertest`, `@types/supertest` | Tests |
| `eslint`, `typescript-eslint`, `@eslint/js`, `eslint-config-prettier`, `prettier` | Qualité |
| `argon2` | Hachage sécurisé des mots de passe (Argon2id, Sprint 1) |
| `jose` | Gestion et vérification JWT ESM sans dépendance native (Sprint 1) |
| `nodemailer`, `@types/nodemailer` | Envoi d'emails transactionnels via SMTP Gmail (Sprint 1) |
| `multer`, `@types/multer` | Upload multipart en mémoire pour `POST /ai/courses/improve-pdf` (PDF 25 Mo max, approuvé avec la demande) |
| `unpdf` | Extraction texte des PDF côté serveur (pdf.js ESM, `Uint8Array` requis — pas `Buffer`) pour `improve-pdf` |

**Volontairement PAS installés maintenant** : `ioredis` / `rate-limit-redis`, `bullmq`, `socket.io`, `@aws-sdk/*`, libs OpenAPI, `husky`, plugins de frontières ESLint. Chacun arrive avec la feature qui en a besoin.

---

## 2. Architecture Globale

### Flux d'une requête

```
HTTP → Route → [validate / auth / rate-limit] → Controller → UseCase → Repository (port) ⇠ PrismaRepository → PostgreSQL
```

### Arborescence cible

```
backend/
├── BACKEND_CONTEXT.md
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── src/
│   ├── main.ts               # bootstrap + graceful shutdown
│   ├── app.ts                # createApp() : middlewares + routes (testable sans listen)
│   ├── routes.ts             # monte /api/v1/<module>
│   ├── config/               # env.ts (Zod, fail-fast)
│   ├── shared/               # Shared Kernel (aucune logique métier)
│   │   ├── errors/           # AppError + sous-classes + catalogue de codes
│   │   ├── http/             # middlewares, validate(), pagination, rate limiters, réponses
│   │   └── infrastructure/   # prisma client, logger
│   └── modules/              # 1 dossier = 1 bounded context (= 1 feature du front)
│       ├── health/           # module de RÉFÉRENCE (4 couches complètes)
│       ├── auth/             # ← frontend: authentication
│       ├── users/            # ← frontend: profile
│       ├── groups/
│       ├── courses/
│       ├── exams/            # inclut anti-fraude
│       ├── videoconference/
│       ├── collaboration/
│       ├── ai-assistant/
│       └── notifications/
├── tests/                    # unit/ integration/
├── Dockerfile                # cibles : dev | build | production
├── docker-compose.yml
├── .env.example  .dockerignore  .gitignore  .gitattributes  .editorconfig
└── package.json  tsconfig.json  eslint.config.mjs  vitest.config.ts
```

### Structure interne d'un module (STRICTE)

```
modules/<name>/
├── domain/          # entités, ports (interfaces), erreurs métier, règles RG pures
├── application/     # use-cases (1 classe = 1 cas d'usage), DTO in/out
├── infrastructure/  # repos Prisma, adaptateurs externes, mappers DB↔Domain
├── presentation/    # routes Express, controllers fins, schémas Zod, mappers HTTP
└── index.ts         # FAÇADE publique (seul point d'entrée pour les autres modules)
```

### Responsabilités par couche

| Couche | Responsabilité | Peut dépendre de |
|--------|----------------|------------------|
| **Domain** | Entités, règles métier (RG), ports, erreurs métier | **Rien** (TS pur : ni Express, ni Prisma, ni Zod) |
| **Application** | Use-cases, orchestration, autorisations métier | Domain |
| **Infrastructure** | Implémentations : Prisma, adaptateurs externes | Domain (implémente ses ports) |
| **Presentation** | HTTP : routes, controllers, validation, mapping réponse | Application, `shared/http` |

**Règles**
- Controller = `lire req validée → appeler UN use-case → mapper → répondre`. Zéro logique métier.
- Prisma n'existe **que** dans `infrastructure/` (et `shared/infrastructure`).
- Un module n'importe **jamais** les fichiers internes d'un autre : uniquement son `index.ts`.
- Ports côté Domain, implémentations côté Infrastructure (**DIP**) → faux en mémoire dans les tests (**LSP**).
- Injection manuelle via un *composition root* par module (`<module>.module.ts`) — pas de décorateurs.

---

## 3. Design Patterns

| Pattern | Où | Pourquoi |
|---------|----|----------|
| **Repository** | port `domain` / impl `infrastructure` | Isoler la persistance |
| **Use-Case** | `application` | 1 intention = 1 classe testable |
| **Dependency Injection** (manuelle) | composition roots | Testabilité |
| **Adapter / Port** | `HealthCheckPort`, plus tard `StoragePort`, `AiGatewayPort`, `MailerPort` | Changer de fournisseur sans toucher au métier |
| **Factory** | `createApp()`, `createRateLimiter()` | Construction contrôlée |
| **Mapper / DTO** | Prisma ↔ Domain ↔ HTTP | **Jamais** exposer une entité DB brute |
| **Chain of Responsibility** | pipeline de middlewares | requestId → logs → sécurité → rate-limit → (auth) → validation → handler |
| **Error hierarchy** | `AppError` → `NotFoundError`… | Gestion d'erreurs uniforme |
| **State machine** (Sprint 2) | `Course`/`Assessment` BROUILLON→VALIDE→PUBLIE | RG4 |
| **Unit of Work** (quand nécessaire) | port sur `prisma.$transaction` | Atomicité multi-agrégats |

## 4. Principes de Code (OBLIGATOIRES)

**SOLID**, **KISS**, **DRY** (sans sur-abstraction), **YAGNI**, **12-Factor** (config par env, logs sur stdout, processus stateless, arrêt gracieux), **fail fast** (l'app ne démarre pas si l'env est invalide), **least privilege**.

### Conventions

```
Fichiers/dossiers : kebab-case   (get-health.use-case.ts)
Classes/Types     : PascalCase
Variables/fonctions : camelCase
Constantes/env    : SCREAMING_SNAKE_CASE
Suffixes          : .use-case.ts .repository.ts .controller.ts .routes.ts .schema.ts .mapper.ts .port.ts .errors.ts
Tests             : *.test.ts dans tests/ (unit/ ou integration/)
Imports (ordre)   : 1. node: 2. packages tiers 3. alias @/ 4. même module (relatif)
```

### Interdits

- ❌ `any`, `@ts-ignore` sans justification écrite
- ❌ `process.env` hors `config/env.ts`
- ❌ `console.log` (utiliser le logger)
- ❌ Prisma/Express/Zod dans `domain/` ; Prisma dans `application/` ou `presentation/`
- ❌ Logique métier dans un controller/route/middleware
- ❌ `$queryRawUnsafe` ou SQL concaténé (uniquement `` $queryRaw`...` `` paramétré)
- ❌ Retourner une entité Prisma brute / passer `req.body` tel quel à Prisma
- ❌ Endpoint de liste **sans pagination**
- ❌ Erreur sans `code` stable
- ❌ Secrets dans le repo, les logs ou l'image Docker
- ❌ Travail CPU bloquant dans l'event loop
- ❌ API qui oblige le client à poller (le front l'interdit)
- ❌ Installer un package hors §1.2 sans accord
- ❌ Créer, modifier ou supprimer un endpoint **sans mettre à jour son contrat** dans `../contracts/` (§5.1)

---

## 5. Conventions API

- **Base** : `/api/v1`. Santé hors versionnement : `/health/live`, `/health/ready`.
- REST, ressources au **pluriel kebab-case** ; verbes seulement pour les actions (`POST /assessments/:id/submit`).
- JSON **camelCase** ; dates **ISO 8601 UTC** ; IDs **UUID** ; enums en `SCREAMING_SNAKE_CASE`.
- **Succès** : `{ "data": ..., "meta"?: {...} }` ; `204` sans corps pour suppression/logout.
- **Erreur** (toujours cette forme) :

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Invalid request", "details": [], "requestId": "..." } }
```

| HTTP | Usage | `error.code` (stables, ne jamais renommer) |
|------|-------|--------------------------------------------|
| 400 | JSON/params mal formés | `BAD_REQUEST` |
| 401 | Non authentifié | `AUTH_INVALID_CREDENTIALS`, `AUTH_TOKEN_EXPIRED`, `AUTH_TOKEN_INVALID`, `AUTH_REFRESH_REUSED` |
| 403 | Interdit | `FORBIDDEN`, `ROLE_ALREADY_ASSIGNED` |
| 404 | Absent | `NOT_FOUND` |
| 409 | Conflit | `EMAIL_ALREADY_USED`, `CONFLICT` |
| 422 | Validation Zod | `VALIDATION_ERROR` (+ `details: [{path, message}]`) |
| 429 | Rate limit | `RATE_LIMITED` (+ `Retry-After`) |
| 500/503 | Interne / dépendance KO | `INTERNAL_ERROR`, `SERVICE_UNAVAILABLE` |

- **i18n** : le backend renvoie un `code` stable + un `message` anglais neutre. **Flutter traduit** via `context.tr('errors.<CODE>')` (règle front : aucun texte hardcodé).
- **IDOR** : vérifier appartenance/rôle sur chaque ressource, pas seulement l'authentification.

### Pagination (OBLIGATOIRE sur toute liste)

| Stratégie | Query | `meta` | Utilisée pour |
|-----------|-------|--------|---------------|
| **Offset** | `?page=1&limit=20` (défaut 20, **max 100**) | `{ page, limit, total, totalPages, hasNextPage, hasPreviousPage }` | groupes, cours, évaluations, utilisateurs |
| **Cursor (keyset)** | `?cursor=<opaque>&limit=20` | `{ limit, nextCursor, hasMore }` | notifications, messages IA, événements anti-fraude |

- Tri **déterministe** (`createdAt` + `id`). Tri/filtres via **liste blanche** (`?sort=createdAt:desc`).
- Liste vide = `200` + `data: []` (le front gère l'état *Empty*).
- Un seul helper `shared/http/pagination` ; ne jamais réimplémenter dans un module.

### 5.1 Contrats OpenAPI (`../contracts/`) — contract-first

`contracts/` (à la racine du monorepo) est le **« README de l'API »** : un fichier **OpenAPI 3.1 en YAML, écrit à la main, par module**. On y lit, sans fouiller le code backend, ce que chaque endpoint **exige** (ex. `POST /auth/register` : `email`, `password`…) et ce qu'il **renvoie** (succès + erreurs).

```
contracts/
├── README.md              # mode d'emploi + TABLEAU D'INDEX (module → fichier → statut)
├── common.yaml            # composants partagés : ErrorResponse, pagination (meta + paramètres), bearerAuth, réponses d'erreur standard
├── health.openapi.yaml
├── auth.openapi.yaml      # créé au Sprint 1
└── <module>.openapi.yaml  # 1 fichier par module (kebab-case), même nom que modules/<name>/
```

**Règles**
- **1 module = 1 fichier** `<module>.openapi.yaml`. Les éléments partagés vivent dans `common.yaml` (référencés par `$ref: './common.yaml#/components/...'`) : on ne les recopie jamais.
- **Contract-first** : avant d'implémenter ou de modifier un endpoint → on écrit/met à jour son contrat, on le montre, **puis** on code pour qu'il corresponde.
- Chaque opération contient : `operationId` unique (camelCase), `tags: [<module>]`, `summary`, `description` (avec les RG concernées), `security` (`bearerAuth`, ou `[]` si public), `requestBody` avec champs `required`, types et contraintes (`minLength`, `maxLength`, `format`, `enum`), **`additionalProperties: false`** (miroir du Zod `.strict()`), au moins un **`example`**, et **toutes** les réponses possibles : succès + chaque erreur avec son `error.code` (§5).
- Listes : paramètres de pagination et `meta` réutilisés depuis `common.yaml`.
- Noms de champs et valeurs d'enums du contrat = ceux du JSON réel (camelCase, enums EN).
- `servers` : `/api/v1` ; exception `health.openapi.yaml` → `/` (les routes de santé sont hors `/api/v1`).
- **`x-status: planned | implemented`** sur chaque opération, et même statut dans le tableau d'index du README. `planned` = contrat défini, endpoint pas encore codé.
- **Besoin manquant côté front** (champ absent, erreur non documentée, endpoint absent) → on l'**ajoute d'abord au contrat** (`x-status: planned`), puis le backend l'implémente.
- **Même tâche = contrat + Zod + tests + index du README.** Contrat et code qui divergent = bug.
- Pas de lib OpenAPI installée pour l'instant (§1.2). Validation ponctuelle possible avec `npx` (non ajouté au `package.json`).

---

## 6. Sécurité (checklist OBLIGATOIRE)

| Domaine | Règle |
|---------|-------|
| **Headers/Transport** | `helmet` ; CORS en **liste blanche** (`CORS_ORIGINS`, jamais `*` avec credentials) ; `x-powered-by` off ; `trust proxy` explicite ; HTTPS terminé en amont |
| **Entrées** | Zod **`.strict()`** sur body/query/params ; body JSON limité (`1mb`) ; UUID validés ; pas de mass assignment |
| **Données** | Prisma paramétré uniquement ; DTO de sortie (jamais de `passwordHash`) ; pas de PII dans les logs ; chiffrement/rétention des vidéos et données de mineurs (RG14) quand elles arrivent |
| **Erreurs** | Aucune stack trace en prod ; erreurs inconnues → `INTERNAL_ERROR` (détail dans les logs seulement) |
| **Logs** | pino avec **redaction** (`authorization`, `cookie`, `password`, `refreshToken`, `token`) ; `X-Request-Id` propagé |
| **Docker** | Image **non-root**, multi-stage, `.dockerignore`, aucun secret dans l'image, ports DB liés à `127.0.0.1`, healthchecks, arrêt gracieux |
| **Anti-abus** | Rate limiting (§7) ; timeouts serveur ; regex simples (pas de ReDoS) |
| **Auth (Sprint 1)** | argon2id ; réponses identiques inconnu/mauvais mot de passe ; access JWT 15 min ; refresh opaque haché, rotatif, détection de réutilisation ; **ADMIN jamais auto-attribuable** ; RG1 (rôle unique) |
| **Dépendances** | `package-lock.json` commité ; `npm audit` régulier |

---

## 7. Rate Limiting

`express-rate-limit`, **store mémoire à l'init** (suffisant pour 1 instance ; passage à Redis quand on aura 2+ instances — décision plus tard). Réponse `429` + `Retry-After` + en-têtes `RateLimit-*` + corps `RATE_LIMITED`. IPv6 géré via l'helper officiel de la lib. Limites configurables par env.

| Portée | Limite par défaut | Clé | Quand |
|--------|-------------------|-----|-------|
| API globale (`/api/v1`) | 100 req / min | IP | **Init** |
| `POST /auth/login` | 10 / 15 min (IP) + 5 / 15 min (IP+email) | IP, IP+email | Sprint 1 |
| `POST /auth/register` | 5 / heure | IP | Sprint 1 |
| `POST /auth/refresh` | 30 / 15 min | IP | Sprint 1 |
| Endpoints IA | 20 / min + quota jour | userId | Sprint 4 |
| Uploads | 10 / min | userId | Sprint 2 |
| `/health/*` | **exempté** | — | Init |

À l'init : le limiteur global + la factory `createRateLimiter(options)` prête pour les limiteurs stricts.

---

## 8. Auth & RBAC (planifié — Sprint 1, PAS dans l'init)

Flux front : inscription → `/role-selection` → `/profile-setup` → `/home` ; compte existant → `/home` (piloté par `onboardingCompleted`).

| Endpoint | Accès | Note |
|----------|-------|------|
| `POST /auth/register` | public | crée le compte `role = null`, `onboardingCompleted = false` + tokens |
| `POST /auth/login` | public | |
| `POST /auth/refresh` | public | rotation + détection de réutilisation |
| `POST /auth/logout` | authentifié | révoque la famille |
| `GET /users/me` | authentifié | |
| `PATCH /users/me/role` | authentifié | `TEACHER`/`STUDENT` **une seule fois** (RG1) ; renvoie une nouvelle paire de tokens |
| `PATCH /users/me/profile` | authentifié | `birthDate` (RG14) → `onboardingCompleted = true` |

---

## 9. Données & Prisma

- Modèles **PascalCase anglais singulier** ; tables `snake_case` pluriel (`@@map`) ; colonnes `snake_case` (`@map`).
- `id` UUID ; `createdAt`/`updatedAt` en `Timestamptz` ; index sur toutes les FK et colonnes filtrées/triées.
- Migrations : `prisma migrate dev` (dev), `prisma migrate deploy` (Docker/prod). **Jamais** modifier une migration appliquée.
- **pgvector** : extension activée dans la 1re migration ; plus tard `IndexedPassage.embedding = Unsupported("vector(768)")` accédé **uniquement** via un repository en `` $queryRaw`` paramétré.
- **À l'init** : seul le modèle `User` (+ enums `Role`, `UserStatus`), `role` **nullable** (inscription avant choix du rôle), `onboardingCompleted` ajouté. Les autres entités arrivent avec leur sprint.

### Glossaire FR (cadrage) → EN (code)

| FR | EN | FR | EN |
|---|---|---|---|
| Utilisateur | `User` | Evaluation | `Assessment` |
| GroupeClasse | `ClassGroup` | EvaluationChapitre | `AssessmentChapter` |
| MembreGroupe | `GroupMember` | Question | `Question` |
| Cours | `Course` | Tentative | `Attempt` |
| Chapitre | `Chapter` | Reponse | `Answer` |
| Document | `Document` | EvenementFraude | `FraudEvent` |
| PassageIndexe | `IndexedPassage` | RapportIntegrite | `IntegrityReport` |
| RessourcePartagee | `SharedResource` | SessionVisio | `VideoSession` |
| ConversationIA | `AiConversation` | ParticipantSession | `SessionParticipant` |
| MessageIA | `AiMessage` | Enregistrement | `Recording` |
| ModeleIA | `AiModel` | CompteRendu | `SessionSummary` |
| Notification | `Notification` | | |

Enums : `ENSEIGNANT→TEACHER`, `ETUDIANT→STUDENT`, `ADMIN→ADMIN` · `ACTIF→ACTIVE`, `SUSPENDU→SUSPENDED` · `EN_ATTENTE→PENDING`, `ACCEPTEE→ACCEPTED`, `REFUSEE→REFUSED` · `BROUILLON→DRAFT`, `VALIDE→VALIDATED`, `PUBLIE→PUBLISHED`, `CLOS→CLOSED` · `MANUEL→MANUAL`, `IA→AI` · `EXAMEN_SIMULE→SIMULATED_EXAM`, `EXAMEN_OFFICIEL→OFFICIAL_EXAM` · `EN_COURS→IN_PROGRESS`, `TERMINEE→COMPLETED`, `INTERROMPUE→INTERRUPTED` · `PLANIFIEE→SCHEDULED` · `FAIBLE/MOYENNE/ELEVEE→LOW/MEDIUM/HIGH`. (Le front mappe `TEACHER` ↔ `teacher`.)

---

## 10. Règles métier → où les implémenter

| RG | Règle (cadrage) | Couche | Sprint |
|----|-----------------|--------|--------|
| RG1 | Un rôle unique par compte | Domain | 1 |
| RG4 | Contenu IA officiel : validation enseignant obligatoire ; l'IA ne publie jamais seule | Domain (state machine) | 2 |
| RG6 | Génération IA individuelle : sans validation | Application | 4 |
| RG7 | Conversation tuteur IA privée | Policy | 4 |
| RG8 | Seul l'enseignant hôte gère l'enregistrement | Policy | 3 |
| RG11 | Résumé de session validé par le prof avant diffusion | Domain | 3 |
| RG12 | Partage de ressource uniquement dans ses groupes | Policy | 5 |
| RG14 | Mineurs + vidéos : chiffrement et rétention | Infra | 3 |
| RG16 | Examen simulé uniquement depuis chapitres publiés/validés | Domain | 5 |
| RG19 | Examen officiel : focus lock, anti copier-coller, plein écran | Domain | 5 |
| RG20/RG26 | Rapport d'intégrité au prof, décision finale au prof | Application | 6 |
| RG21 | Rétention logs anti-fraude 30-90 j | Job de purge | 6 |
| RG25 | Consentement webcam avant examen officiel ; refus → mode entraînement | Application | 6 |
| RG27 | Modèles auto-hébergés, aucune donnée vers un LLM tiers | Config + `AiGatewayPort` | 2+ |
| RG28 | Modèle IA versionné/évalué avant production | `AiModel.status` | 2+ |
| RG29 | Chaque question IA liée à un passage source | Domain | 4 |

> ⚠️ **À confirmer avec le product owner** : RG2, RG3, RG5, RG10, RG13, RG24 sont citées dans le cadrage mais **leur énoncé est absent** de l'export HTML ; et la numérotation est **incohérente** (consentement webcam cité RG27 dans un schéma, RG25 ailleurs, alors que RG27 = modèles auto-hébergés). Ne pas deviner.

---

## 11. Docker & Environnements

| Service | Image | Port hôte | Healthcheck |
|---------|-------|-----------|-------------|
| `api` | build local (cible `dev`) | `3000` | script Node sur `/health/live` (pas de `curl`) |
| `db` | `pgvector/pgvector:pg17` | `127.0.0.1:5432` | `pg_isready` |

- `api` dépend de `db` avec `condition: service_healthy`.
- Démarrage dev : `prisma migrate deploy` puis `tsx watch`, **commande inline** dans le compose (hôte **Windows** : les `.sh` en CRLF cassent dans Linux → `.gitattributes` force LF).
- `Dockerfile` multi-stage `dev → build → production` ; image Debian-slim ; utilisateur `node` ; `NODE_ENV=production` ; deps de prod seulement.

### Variables d'environnement (`.env.example` commité, `.env` ignoré)

| Variable | Rôle | Exemple |
|----------|------|---------|
| `NODE_ENV` | env | `development` |
| `PORT` | port HTTP | `3000` |
| `LOG_LEVEL` | niveau pino | `info` |
| `DATABASE_URL` | Postgres | `postgresql://smartclass:***@db:5432/smartclass` |
| `CORS_ORIGINS` | origines autorisées, séparées par virgules | `http://localhost:5000` |
| `TRUST_PROXY` | proxies de confiance | `0` |
| `RATE_LIMIT_WINDOW_MS` / `RATE_LIMIT_MAX` | limiteur global | `60000` / `100` |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | compose | — |
| `AI_BASE_URL` / `AI_MODEL` / `AI_API_KEY` | gateway LLM local (Unsloth, OpenAI-compatible, clé jamais commitée — `.env` ignoré) | `http://host.docker.internal:8888` / `unsloth/Qwen3.5-4B-GGUF` / vide |
| `AI_TIMEOUT_MS` / `AI_STATUS_TIMEOUT_MS` | timeout génération / sonde status | `300000` / `5000` |
| `AI_MAX_TOKENS` / `AI_TEMPERATURE` | budget sortie (32K pour cours détaillés — régler la fenêtre contexte d'Unsloth ≥ 34K en conséquence) / créativité | `32768` / `0.7` |
| `AI_MAX_SOURCE_CHARS` / `AI_ENABLE_WEB_SEARCH` | troncature source / outil web_search | `16000` / `true` |
| `AI_PERMISSION_MODE` | Unsloth : exécution des outils sans confirmation (`off`) | `off` |
| `AI_FALLBACK_MODEL` | modèle de repli quand `AI_MODEL` est indisponible | `hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1` |
| `EMBEDDING_BASE_URL` | serveur d'embeddings Ollama (RG27, local) | `http://host.docker.internal:11434` |
| `EMBEDDING_MODEL` | modèle d'embeddings, 768 dims (match du `vector(768)`) | `embeddinggemma` |
| `EMBEDDING_TIMEOUT_MS` | timeout appel embeddings (dégradation gracieuse) | `10000` |
| `COMFYUI_BASE_URL` | base ComfyUI appelée par le **backend** (depuis Docker : `host.docker.internal:8188` vérifié 200 ; IP LAN depuis un appareil, ComfyUI doit `--listen 0.0.0.0`) ; vide = désactivé → 503 `IMAGE_SERVICE_UNAVAILABLE` | `` |
| `COMFYUI_PUBLIC_URL` | origine de `imageUrl` rendue à **l'app** (elle résout son propre hôte : `host.docker.internal` est Docker-only) ; vide = réutilise `COMFYUI_BASE_URL` | `` |

---

## 12. Qualité, Tests, Git

- **unit** (use-cases/domaine avec faux en mémoire, helpers) + **integration** (Supertest sur `createApp()`).
- Scripts : `dev`, `build`, `start`, `lint`, `typecheck`, `test`, `test:watch`, `db:migrate`, `db:deploy`.
- **Conventional Commits** (`feat:`, `fix:`, `chore:`…).
- **Definition of Done** : lint ✅ typecheck ✅ tests ✅ `docker compose up` sain ✅ **contrat OpenAPI à jour** ✅ ce fichier mis à jour ✅.

## 13. Observabilité & cycle de vie

- Logs JSON (pino-http), `requestId` par requête, secrets masqués.
- `/health/live` = le process répond (aucune dépendance). `/health/ready` = DB OK (sinon `503` + détail par dépendance).
- **Graceful shutdown** : SIGTERM/SIGINT → stop nouvelles connexions → drain → fermeture Prisma → exit (timeout 10 s).

## 14. Contrat avec le Frontend Flutter

- URL de base par environnement ; le front remplace ses `Mock*DataSource` par des `Remote*DataSource` (Dio/Retrofit) **sans toucher Domain/Presentation** → les JSON doivent correspondre aux `fromJson/toJson` des modèles Flutter : **vérifier `../contracts/` puis `../docs/FRONTEND_CONTEXT.md` avant d'inventer un champ**. Le contrat OpenAPI de l'endpoint est la référence que le front consulte.
- `401` + `AUTH_TOKEN_EXPIRED` → le front appelle `/auth/refresh` puis rejoue une fois.
- Codes d'erreur ↔ clés i18n `errors.*` ; `meta` de pagination ↔ états `AsyncValue` (Loading/Empty/Error).
- CORS : autoriser l'origine du Flutter Web. Temps réel : WebSocket/SSE, jamais de polling.

## 15. Fichiers clés

| Fichier | Rôle |
|---------|------|
| `src/main.ts` | Bootstrap, listen, graceful shutdown |
| `src/app.ts` | `createApp()` — utilisé aussi par les tests |
| `src/config/env.ts` | Seul lieu de lecture de `process.env` |
| `src/shared/errors/` | `AppError` + catalogue de codes |
| `src/shared/http/` | middlewares, `validate()`, pagination, rate limiters |
| `prisma/schema.prisma` | Source de vérité du schéma |
| `../contracts/*.openapi.yaml` | Contrat de chaque API (contract-first, §5.1) |
| `modules/health/**` | **Module de référence** : copier son découpage pour tout nouveau module |

## 16. Statut d'avancement (à tenir à jour)

| Sprint | Périmètre backend | Statut |
|--------|-------------------|--------|
| 0 | Init : squelette, Docker (api+db), health, kernel (erreurs, validation, pagination, rate limit, logs), Prisma + `User`, dossier `contracts/` (README, `common.yaml`, `health.openapi.yaml`) | ✅ Terminé |
| 1 | UC8 Auth & profil, UC6 Groupes-classes, RBAC & Invitations (RG1-RG3) | ✅ Terminé (Auth, OTP email, profil, RBAC 3 rôles ADMIN/TEACHER/STUDENT, CRUD classes, invitations par code/lien, scoping cours-classes) |
| 2 | UC1 Cours + upload/extraction PDF + LLM local + validation prof + scoping classes (RG4-RG5) | ✅ Terminé (Génération LLM Unsloth topic/text/url/PDF, streaming SSE, module Courses + scoping cours-classes, validation RG4 par **build section par section** : outline → PENDING → GENERATED → VALIDATED, publication 409 tant que toutes ne sont pas validées, mémoire vectorielle pgvector scopée auteur) |
| 3 | UC3/UC4 Visio, enregistrement, Whisper, résumé (RG8-RG11) | ⬜ |
| 4 | UC2/UC10 IA individuelle, RAG pgvector (RG6-RG7, RG29) | ⬜ |
| 5 | UC5 Collaboration, UC9 v1 Examen (RG12-RG13, RG16-RG19) | ⬜ |
| 6 | UC9 v2 Anti-fraude avancé, UC7 Suivi (RG20-RG28) | ⬜ |

## 17. Commandes utiles

```bash
docker compose up -d --build       # tout démarrer
docker compose ps                  # api et db doivent être "healthy"
docker compose logs -f api
docker compose down                # (-v supprime les volumes)

docker compose exec api npm run lint
docker compose exec api npm run typecheck
docker compose exec api npm test
docker compose exec api npm run db:migrate -- --name <nom>
```

## 18. Rappels, décisions ouvertes & journal

> **Tout nouveau code doit respecter :** Clean Architecture stricte (module de référence = `health`) · Zod `.strict()` en entrée, DTO/mappers en sortie · pagination + rate limiting sur ce qui s'y applique · erreurs = `AppError` + `code` stable · aucun secret en clair · politique des packages §1.2 · **contrat OpenAPI écrit/à jour avant et avec chaque endpoint (§5.1)** · tests + lint + typecheck avant « terminé » · **mettre à jour ce fichier**.

**Décisions ouvertes**
- [x] Packages d'auth (Sprint 1) — `argon2` (Argon2id) + `jose` (JWT ES/HS256) validés et installés
- [x] Fournisseur e-mail/push (Sprint 1) — `nodemailer` configuré via SMTP Gmail (`faroukmessay006@gmail.com`) avec templates HTML réactifs
- [ ] Validation/génération automatique des contrats (lint OpenAPI, client Dart pour Dio/Retrofit) — quand le front branche l'API
- [ ] Redis (rate limit partagé / jobs) — quand 2+ instances
- [ ] Moteur S3 (SeaweedFS / Garage / RustFS / managé) — Sprint 2
- [ ] Fournisseur visio (LiveKit vs Jitsi) — Sprint 3
- [ ] Modèle d'embedding → dimension du `vector(n)` — Sprint 2/4
- [ ] Durées de rétention (vidéos, snapshots) — RG14/RG21
- [ ] Énoncés de RG2, RG3, RG5, RG10, RG13, RG24 + correction de la numérotation RG25/RG27

**Journal**
- 2026-10-05 — v1.0.0 — Création du contexte backend (périmètre : initialisation).
- 2026-10-05 — v1.1.0 — Monorepo (`front/ backend/ docs/ contracts/`) ; ajout des contrats OpenAPI contract-first (§5.1).
- 2026-10-05 — v1.2.0 — Initialisation backend complète (Sprint 0) : scaffold Express 5 / Node 24 / TS strict, Dockerfile multi-stage, docker-compose avec healthchecks (`api` et `db` postgres17+pgvector), shared kernel (env fail-fast, Pino avec redaction, AppError, validation Zod, pagination offset/cursor, rate limiter), schéma Prisma 7 avec User & extension vector, module de référence Health (Clean Architecture 4 couches), contrats OpenAPI 3.1 (`common.yaml`, `health.openapi.yaml`), suite de 46 tests unitaires et d'intégration 100% verts, README technique.
- 2026-10-06 — v1.3.0 — Implémentation complète du système d'authentification (Sprint 1, UC8) : 9 endpoints REST (`/auth/*`), schéma relationnel complet (`User`, `RefreshToken`, `EmailVerificationCode`, `PasswordResetCode`), hachage Argon2id, tokens rotatifs avec détection de réutilisation, OTP par email (6 chiffres, 15 min, max 3 tentatives), blocage temporaire automatique de 5 minutes après 3 tentatives de mot de passe erronées (HTTP 423 `AUTH_ACCOUNT_LOCKED`), Zod strict, contrat OpenAPI 3.1 `contracts/auth.openapi.yaml`, 14 nouveaux tests unitaires/intégration (60/60 tests au total verts).
- 2026-10-06 — v1.3.1 — Support des 3 types de comptes (`STUDENT`, `TEACHER`, `ADMIN` avec normalisation des alias FR/EN), endpoints d'accès et mise à jour du profil (`GET /auth/profile`, `PATCH /auth/profile`), adaptateur Nodemailer SMTP Gmail (`faroukmessay006@gmail.com`), middleware de contrôle d'accès par rôle (`createRequireRoleMiddleware`), contrat OpenAPI 3.1 mis à jour, 65/65 tests verts.
- 2026-10-10 — v1.3.2 — Emails OTP réellement envoyés via relais local sans auth (MailHog/Mailpit) : `NodemailerSmtpEmailAdapter` crée désormais toujours le transporteur (auth ajoutée uniquement si `SMTP_USER`+`SMTP_PASS` définis, `ignoreTLS` pour les relais locaux en clair). `.env` local : `SMTP_HOST=host.docker.internal`, `SMTP_PORT=1025` (le backend tourne dans Docker : `localhost` pointerait vers le conteneur). Vérifié E2E : register → OTP MailHog → verify → login → forgot → OTP MailHog → reset → login.
- 2026-10-11 — v1.4.0 — Endpoints admin pour les 7 écrans Flutter du rôle responsable : 14 endpoints sur 4 modules (`users` : directory paginé ; `groups` : CRUD classes, assignation étudiants/enseignants atomique ; `exams` : rapports de fraude paginés cursor + résumé + transitions verrouillées ; `videoconference` : emploi du temps hebdomadaire borné). RBAC ADMIN-only via `requireRoleMiddleware`, IDOR documenté (élargissement TEACHER plus tard). Correctif partagé : `validate()` ne réassigne plus `req.query` (getter-only sous Express 5) + helper `validatedQuery()` + `sortQuerySchema()` whitelistée (422). Seed démo (`db:seed`), migration `20261011002231_admin_modules`, contrats `users/groups/exams/videoconference.openapi.yaml` + index README. Suite 91/91 verte (13 fichiers), E2E live vérifié en ADMIN.
- 2026-10-11 — v1.4.1 — Vérification d'email en direct pendant l'inscription : `POST /api/v1/auth/check-email` (`{email}` → `{available, email}`, rate-limiter auth partagé, miroir exact de la condition de doublon de register). Oracle d'existence assumé et documenté (le 409 de register le révélait déjà ; réponse limitée au booléen, aucune PII). Front : `checkEmailAvailability` dans repository/datasource/notifier (sans toucher l'état global), debounce 600 ms + garde anti-réponses obsolètes + spinner + erreur inline `email_already_exists` dans `register_page`. Suite 99/99 verte (15 fichiers), E2E live vérifié.
- 2026-10-11 — v1.4.2 — Rôle null à l'inscription (RG1) + garde ADMIN réparée : `registerSchema` n'applique plus `.default('STUDENT')` (rôle omis/null → `null`, choisi ensuite sur `/role-selection` via `PATCH /users/me/role`, sinon le once-only était consommé avant l'onboarding et tout nouveau compte restait bloqué en STUDENT). `SetMyRoleUseCase.execute` appelle désormais `assertAssignableRole` (garde 403 jamais branchée auparavant) ; `setMyRoleBodySchema` accepte ADMIN pour laisser le use-case répondre le 403 documenté (Zod n'est pas la frontière sécu) ; composition root `createUsersModule` réparée (construit `SetMyRole`/`SetUserRole` + supprime l'import dupliqué qui cassait le chargement des 7 fichiers d'intégration ; `UsersController` recevait 1 arg au lieu de 3 → 500 sur les routes rôle). Contrats `auth`/`users.openapi.yaml` alignés. Tests : 114/114 verts (17 fichiers), E2E live vérifié (register → null → login → PATCH TEACHER 200 + tokens frais → GET /me TEACHER → re-PATCH 409 → PATCH ADMIN 403). Comptes `admin@gmail.com`, `admin1@gmail.com` (créé, `Admin123!`), `admin2@gmail.com` promus ADMIN en base (tokens révoqués, reconnexion requise).
- 2026-10-11 — v1.5.0 — Données admin 100 % réelles (zéro mock côté front) : 8 nouveaux endpoints ADMIN-only, contract-first. Nouveau module `admin` : `GET /admin/overview` (totaux + nouveaux du mois + % actifs + inscrits + synthèse fraudes, `contracts/admin.openapi.yaml`). Module `groups` étendu : `GET /groups/departments` (filières réellement utilisées, avant `/:id`), `PATCH /groups/:id` (dont `referentId` TEACHER-only, `null` = retire), `DELETE /groups/:id` (204, cascades), `GET+DELETE /groups/:id/members`, `GET+DELETE /groups/:id/teachers` (avec identité), `referentId` accepté au POST. Pas de taux de présence/intégrité/remplissage (aucun dénominateur server-side — le front n'affiche plus ces chiffres), pas de CRUD timetable ni module courses (reportés, documentés). Suite 133/133 verte (18 fichiers), E2E live vérifié (overview, departments, members, teachers, timetable). Front : `AdminRemoteDataSource` + `AdminRepositoryImpl` réel (`MockAdminDataSource` supprimé), création de classe avec filières réelles + saisie libre + référent, assignations/retraits réels, transitions fraude UNTREATED→IN_PROGRESS→CLOSED avec résolution, planning par classe sélectionnée, dashboard sur compteurs réels, annuaires globaux `/admin/teachers` + `/admin/students` avec affectation.
- 2026-10-11 — v1.5.1 — Membership étudiant temps réel : `GET /groups/mine` (tout rôle authentifié, avant le guard ADMIN et `/:id`) → classes du caller avec `myRole` (STUDENT/TEACHER/REFERENT, priorité référent) + `joinedAt` ; le dashboard étudiant s'ouvre dès l'affectation (gate pilotée par ce endpoint, plus de « aucune classe » fantôme). Options d'affectation masquées si déjà affecté (cases/boutons assigner cachés, retraits conservés, pré-vérification + snackbar dans les annuaires). Tests rendus indépendants du seed (`promoter_*` créé + promu via Prisma). Suite 135/135 verte (18 fichiers). Contrats `groups.openapi.yaml` (op `listMyGroups` + schéma `MyClassGroup`) alignés. Base dev nettoyée sur demande : 2 users (`amine@gmail.com` STUDENT, `admin@gmail.com` ADMIN), 1 classe + 1 membre réels, 0 fraude (ajout manuel par l'utilisateur) ; ne plus lancer `npm test` contre la base dev (les tests d'intégration y recréent des fixtures).
- 2026-10-11 — v1.6.0 — Dashboard prof réel + génération de cours IA (Unsloth local, RG27). Côté prof : `GET /groups/mine` expose désormais `mySubjects` (matières des affectations) ; `GET /videoconference/timetable` n'est plus ADMIN-only mais class-scoped (ADMIN partout, sinon membre/enseignant/référent de la classe, 403 sinon) ; front `teacherDashboardProvider` réel (classes, Σ étudiants, matières, prochain créneau via timetables) + notice « aucune classe » si non affecté (mocks prof supprimés). Profil onboarding : niveau/filière exigés pour les seuls étudiants (profs et admins : établissement uniquement). Nouveau module `ai-assistant` (`/api/v1/ai`, TEACHER/ADMIN, rate-limit strict 20/min/prof) : `POST /ai/courses/generate` (modes `topic|text|url`, niveaux `concis|equilibre|detaille` qui reshapent la consigne, formats `resume|flashcards|carte-mentale`, prompt versionné `2026-10-11.v1`, sortie >16K via `AI_MAX_TOKENS=16384`, outil `web_search` proposé avec dégradation sans outils si le serveur ne le supporte pas, fetch d'URL natif sans dépendance, 503 honnête quand Unsloth est fermé) + `GET /ai/status` (sonde `/v1/models`, jamais 500). Front : page création branchée (modes, niveaux, formats, matières réelles du prof, statut modèle réel, résultat sélectionnable + métadonnées). Contrats `groups|videoconference|ai-assistant.openapi.yaml` + index alignés. Suite 155/155 verte (21 fichiers), E2E live vérifié (status `available:false` sans Unsloth, generate → 503 documenté). RAG pgvector + upload PDF binaire reportés : nécessitent un modèle d'embedding et les packages `multer` + parseur PDF (approbation demandée) ; en attendant le mode `text` accepte le contenu extrait collé.
- 2026-10-11 — v1.6.1 — Upload PDF direct pour l'amélioration de cours : `POST /ai/courses/improve-pdf` (multipart `file`, 25 Mo max, filtre PDF + magic bytes `%PDF`, extraction `unpdf`, rejets 422 honnêtes : non-PDF, illisible/protégé, <100 caractères). UI : modes Sujet/PDF/Lien (`file_picker` v13 — API `FilePicker.pickFiles` → `List<PlatformFile>`, lecture via `readAsBytes()`), pré-contrôle 25 Mo côté app, carte fichier avec retrait. Leçons apprises : `unpdf.extractText` exige `Uint8Array` (pas `Buffer`) et tronque les PDF à un seul bloc `Tj` géant (fixtures multi-`Tj` comme les vrais PDF). Suite 160/160 verte (21 fichiers), E2E live (PDF valide → 503 modèle éteint, txt → 422, sans fichier → 422). Base dev renettoyée (3 vrais comptes, MPDAM2 2026 + amine, 0 fraude).
- 2026-10-11 — v1.6.2 — Génération orientée **cours** (plus de résumé) + connexion Unsloth réelle. Config mesurée : Unsloth sur `:8888` avec clé obligatoire (même sur `GET /v1/models` — la sonde la transmet désormais), modèle `unsloth/Qwen3.5-4B-GGUF`, **fenêtre 16K totale** → `AI_MAX_TOKENS=8192`, `AI_MAX_SOURCE_CHARS=16000` ; clé dans le `.env` local ignoré uniquement (jamais commitée/loggée). Leçon ops : `docker compose restart` ne recharge PAS le `.env` — recréer (`up -d`). Prompt v2 : **difficulté** (facile/moyen/difficile) + **extras** (exemples simples, figures mermaid, images web depuis résultats de recherche uniquement) ; **un endpoint par méthode** (`from-topic`, `from-url`, `improve-pdf`, `generate` générique conservé) ; 401/403 LLM mappés en 500 explicite (clé). Tests hermétiques au host (gateway fake → 503 déterministe). Suite 165/165 verte (21 fichiers), **vraie génération E2E vérifiée** (657+1656 tokens, cours AVL en français). Front : page création (difficulté, Court/Normal/Long, extras à cocher, 3 endpoints dédiés, `file_picker` v13). RAG/embedding toujours ouvert (pas de `/v1/embeddings` constaté).
- 2026-10-11 — v1.6.3 — Progression live (SSE) + édition avant validation : `POST /ai/courses/stream` (mode topic/text/url) et `POST /ai/courses/improve-pdf-stream` relaient les deltas Unsloth en `text/event-stream` (`data: {"delta"}`, final `{"done":true,...meta}`, erreurs en `{"error"}` avec HTTP 200 — contrat documenté), même rate-limit strict ; 401/403 LLM → 500 explicite ; tests hermétiques (fakes + stub SSE local). Suite 169/169 verte (21 fichiers), E2E live (deltas temps réel constatés). Front : carte de progression live (texte qui s'affiche, tokens + temps écoulé, annulation via CancelToken), édition du résultat (Modifier/Valider), copie presse-papiers, estimation corrigée (2-4 min). Base dev renettoyée (3 vrais comptes, MPDAM2 2026 + amine, 0 fraude).

**Décisions ouvertes (ajoutées)**
- Taux d'intégrité 99,4 % de la maquette **non exposé** : aucun dénominateur (sessions d'examen) sans le moteur d'examens — le front ne doit pas afficher un taux fabriqué (noté dans le contrat `summary`).
- Transitions de fraude accordées à ADMIN alors que RG20/RG26 réservent la décision finale au prof : la maquette admin l'exige ; élargissement TEACHER prévu avec le module exams complet.
- Tri `sort` des listes : whitelist Zod (422) + normalisation `parseSort` conservée en garde-fou.
- `tsx watch` n'a pas toujours rechargé le conteneur live après ajouts de fichiers : en cas de doute, `docker compose restart api`.

---

- 2026-10-11 — v1.6.4 — Exécution réelle des outils Unsloth : le serveur refusait toute requête avec `tools` (400 `confirm_tool_calls requires ... permission_mode 'off'`) et on dégradait silencieusement sans outils. Ajout de `permission_mode: 'off'` (env `AI_PERMISSION_MODE`, défaut `off`) + en-tête `X-Unsloth-Events: 1` dans `unslothParams()`/en-têtes quand des outils sont déclarés (chat + stream) — prompt-outils maintenant fonctionnel. Correctif test `ai-gateway.test.ts` : le cas « API key » n'était pas fermé (it imbriqué, structure cassée) — assertion sur les en-têtes + `});` restaurée. Suite 170/170 verte (21 fichiers), E2E live (stream topic + outils → 200 deltas). Front associé : payload `extras` imbriqué corrigé (le front envoyait `exExamples`/`exMermaid`/`exWebImages` en clés racines → 422 affiché « Erreur du serveur »), cœur d'erreur stream drainé.

- 2026-10-12 — v1.6.5 — Prompt de cours v4 structuré par niveau : `concis` = COURS COURT (titre, objectifs, points clés avec mini-exemple, quiz 3 QCM + correction) ; `equilibre` = COURS NORMAL (plan, intro, parties avec exemple résolu chacune, étude de cas + correction, quiz 5 QCM, correction avec explications, conclusion) ; `detaille` = même ossature mais sous-sections `### A.x`, démonstrations, ≥3 exercices corrigés dont un challenge. Le format `resume` ne contredira plus la structure imposée par le niveau. `AI_MAX_TOKENS` passe à 32768 (fenêtre Unsloth à régler ≥34K). Tests du prompt mis à jour (assertions versionnées). Suite 170/170 verte.

- 2026-10-12 — v1.6.6 — Prompt de cours v5 : `concis` = COURS COURT remplace le résumé express (titre, objectifs, synthèse, points clés avec mini-exemple, quiz 5 QCM + correction) ; normal/complet inchangés dans l'ossature. Mermaid restreint aux types supportés par `flutter_mermaid: 0.1.0` (`graph`/`flowchart`, `sequenceDiagram`, `pie`, `gantt`, `timeline` — `mindmap` INTERDIT, remplacé par `graph TD` hiérarchique, y compris pour le format `carte-mentale`). Budget sortie par niveau via `maxTokensForLevel` (court 8K, normal 20K, complet 32K plafonné par `AI_MAX_TOKENS`) appliqué aux 4 chemins (generate + stream, improve-pdf + stream). Contrat OpenAPI §ai mis à jour. Front associé : labels `Cours court/normal/complet` + `Cours structuré`, fallback brut pour `mindmap`.

*Dernière mise à jour : 2026-10-18 · Version : 1.9.1*

- 2026-10-12 — v1.7.0 — Module Courses (`/api/v1/courses`, contrat `courses.openapi.yaml`) : modèle Prisma `Course` (titre, sujet, contenu Markdown, niveau/difficulté/format, statut DRAFT/PUBLISHED, auteur). POST `/` (TEACHER/ADMIN) sauvegarde une génération en DRAFT ; GET `/mine` (enseignant), GET `/published` (tout authentifié), GET `/:id` (publié visible par tous, brouillon auteur/admin sinon 404), PATCH `/:id/publish|unpublish` + DELETE (auteur ou ADMIN). **DB : aucune migration committée dans le repo — appliquer le schéma via `docker compose exec api npx prisma db push` (puis restart api pour régénérer le client).** Tests unitaires `tests/unit/courses.use-cases.test.ts` (fake repository).
- 2026-10-12 — v1.7.1 — Phases visibles sur `improve-pdf-stream` : le run PDF restait à « 0 tokens » sans dire s'il extrayait ou générait. `ImprovePdfUseCase.stream` accepte `onPhase` (`generating` après extraction), le contrôleur envoie `extracting` dès les headers ; l'app relaie vers la carte de progrès (« Analyse du PDF… »). `sendTimeout` du stream client porté à 5 min (gros PDF). Contrats §ai mis à jour.
- 2026-10-12 — v1.6.9 — Choix des outils côté enseignant (plus de hardcode backend) : `GenerateExtras` gagne `webSearch` + `thinking` (validation Zod stricte mise à jour, défauts `false`). `shouldOfferTools` = toggle enseignant (`webSearch`, ou `webImages` qui implique la recherche) + kill switch `AI_ENABLE_WEB_SEARCH`. Thinking = toggle enseignant direct. UI mobile : 2 nouvelles cases dans « Contenu du cours » — « Recherche web + outils » et « Réflexion approfondie », avec descriptions du coût (~20 s / lent) ; envoyées sur les 3 modes (topic/url/pdf). Contrat OpenAPI §extras étendu.
- 2026-10-12 — v1.6.8 — Prompt v6 anti-stall : constat Unsloth (first token à 8-23 s puis réponse vide) = le modèle émet des appels d'outils imposés par « utilise activement web_search » puis attend leur exécution serveur sans streamer de texte. `shouldOfferTools` n'attache `COURSE_TOOLS` que si utile (images web, mode url, niveau detaille ou difficulté difficile) ; le paragraphe Outils du prompt suit le flag `toolsOffered` (jamais d'outils fantômes : « n'émet aucun appel d'outil » sinon). Flag `thinking` par requête (detaille/difficile uniquement, envoyé même sans outils) ; warn log si le stream gateway reste silencieux 90 s+. `.env.example` corrigé (contexte Unsloth ≥32768 requis, budgets 8K/20K/32K).
- 2026-10-12 — v1.6.7 — Fix faux « pas de connexion internet » en génération : le `receiveTimeout` Dio de 15 s tuait le stream alors que le modèle local reste silencieux 20 s+ avant le premier token (outils serveur). `postStream` utilise désormais `ApiConfig.streamReceiveTimeout` (10 min) et le contrôleur SSE envoie un commentaire `: ping` toutes les 10 s (ignoré par le parser client). Rappel : fenêtre de contexte Unsloth ≥34K requise pour les budgets 20K/32K (observé : contexte à 16384).
- 2026-10-16 — v1.8.0 — Système RBAC complet, gestion des classes et invitations (ADMIN/TEACHER/STUDENT) + scoping cours-classes + assainissement erreurs frontend/backend :
  - Backend : injection de `GroupRepositoryPort` dans `SaveCourseUseCase`, `UpdateCourseUseCase`, `GetCourseUseCase`, `ListPublishedCoursesUseCase`. Les enseignants ne peuvent assigner des cours qu'aux classes où ils enseignent (`isTeacherAuthorizedForGroup`). Les étudiants ne peuvent voir/lister que les cours assignés à leurs classes inscrites (404 Not Found si non inscrit afin d'éviter tout oracle d'existence). 163/163 tests unitaires verts.
  - Frontend : élimination complète de tous les avertissements, dead null-aware checks sur surfaces Material 3, imports et variables inutilisés, lints Dart 3.8. `flutter analyze` retourne 0 problème (exit code 0), 33/33 tests Flutter verts.

- 2026-10-18 — v1.9.0 — **Génération de cours par sections validées + mémoire vectorielle pgvector** (RG4/RG27, plan Phases 0-3) :
  - **Config** (`src/config/env.ts` + `.env.example`) : `AI_FALLBACK_MODEL` (`hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1`), `EMBEDDING_BASE_URL` (`http://host.docker.internal:11434`), `EMBEDDING_MODEL` (`embeddinggemma`, 768 dims), `EMBEDDING_TIMEOUT_MS` (`10000`), `COMFYUI_BASE_URL` (vide = stub).
  - **DB** (aucune migration committée — `npx prisma db push` puis restart api) : enums `SectionStatus` (`PENDING|GENERATED|VALIDATED`) et `PassageKind`, `Course.outline Json?`, table `CourseSection` (unique `(courseId, sectionKey)`, `keyTopics String[]`, `status`, `order`, `estimatedMinutes`), table `CoursePassage` avec `embedding Unsupported("vector(768)")`.
  - **Erreurs** : `SECTIONS_NOT_VALIDATED` (409) et `IMAGE_SERVICE_UNAVAILABLE` (503) dans `error-codes.ts` + `SectionsNotValidatedError` / `ImageServiceUnavailableError` dans `app-error.ts`.
  - **Ports/adapters (Clean Architecture)** : `EmbeddingPort` → `OllamaEmbeddingAdapter` (`/v1/embeddings` d'Ollama, modèle local, timeout → dégradation gracieuse, jamais de blocage) ; `SectionMemoryPort` → `PrismaSectionMemoryAdapter` (recherche pgvector par `<=>` cosine **scopée `authorId`**, top-K, seuil de similarité, fallback liste vide) ; `ImageGeneratorPort` → `ComfyUIImageAdapter` (stub 503 `IMAGE_SERVICE_UNAVAILABLE` tant que les nœuds ComfyUI de l'utilisateur ne sont pas prêts — aucun service externe, RG27).
  - **Module `courses`** : `course-section.entity.ts` + port repository + adaptateur Prisma ; `saveCourse` accepte `outline` (Zod `.passthrough()`), `CourseDetail` expose `outline` ; `publish` refuse avec **409 `SECTIONS_NOT_VALIDATED`** si `countNotValidated > 0` (un cours sans sections publie normalement).
  - **Module `ai-assistant`** : prompts `buildSectionPrompt` (rédaction d'une section avec contexte du plan + **rappel des anciens cours validés** via mémoire) ; use-cases `course-access` (IDOR : 404 si `authorId != caller && role != ADMIN`), `section-memory.service` (remember au validate, recall best-effort), `get-course-build` (initialisation paresseuse des sections depuis l'outline au premier appel), `generate-section` (SSE : phase `memory` puis `generating`, delta→contenu, retour `done` avec la section sauvegardée, `regenerate` repasse VALIDATED→GENERATED — RG4), `validate-section` (VALIDATED + insertion mémoire vectorielle + réassemblage du corps `courses.content`), `refine-section` (drift corrigé : renvoie **et** `refinedText` **et** `revisedText`), `generate-section-image` (503 documenté) ; 9 handlers + routes + câblage `ai-assistant.module.ts` (repositories réels injectés). Le level/difficulté du cours est relayé au prompt.
  - **Contrats** : `ai-assistant.openapi.yaml` +7 paths (`generate-outline`, `refine-section`, `courses/{id}/build`, `sections/generate|regenerate|validate|image`) + fix bug préexistant de clés dupliquées (`webSearch`/`thinking`) ; `courses.openapi.yaml` (`outline`, `classGroupIds`, 409 publish, `CourseDetail.outline`) ; index README mis à jour ; **hygiène repo-wide des contrats** : 34 `nullable: true` → unions `type: [x, 'null']` (OAS 3.1), `securitySchemes.bearerAuth` ajouté dans 8 fichiers module, refs auth cassées renommées (`BadRequest`/`Unauthorized`), `security: []` sur 9 opérations auth publiques, 4 spots `$ref`+`nullable` convertis en `oneOf`, `common.yaml` (`servers: /api/v1` + enum des 22 codes synchronisée avec `error-codes.ts`) → **redocly lint : 98 erreurs → 0 (EXIT=0)**, 51 warnings de dette préexistante non bloquants.
  - **Qualité** : nouveau `tests/unit/section-build.use-cases.test.ts` (26 tests) ; suite **239/239 vertes (24 fichiers)**, `npm run typecheck` 0 erreur, lint 34 erreurs toutes préexistantes. Front associé v1.9.0 (voir `../Frontend/PROJECT_CONTEXT.md`).

- 2026-10-18 — v1.9.1 — **Illustrations de sections : ComfyUI réel (workflow SDXL 512×512)** :
  - **Workflow** : `image_sdxl_simple.json` (fourni par l'utilisateur, format API ComfyUI : CheckpointLoaderSimple `sd_xl_base_1.0.safetensors` → CLIPTextEncode ± → KSampler 30 steps cfg 8 `uni_pc_bh2` → VAEDecode → SaveImage) déplacé depuis la racine `Backend/` vers `src/modules/ai-assistant/infrastructure/` et importé via `import … with { type: 'json' }` — `tsc` émet le JSON vers `dist/…` (indispensable : l'image Docker production ne copie que `dist/`). Résolution passée de 1024 à **512×512** dans le fichier, et ré-écrasée à l'exécution sur le nœud `EmptyLatentImage` (`IMAGE_SIZE = 512`).
  - **Adapter** `ComfyUIImageAdapter` implémenté (remplace le stub) : clone le workflow, réécrit le prompt positif (`buildImagePrompt` = kind + titre + points clés), tire un seed aléatoire (`crypto.randomInt`), POST sur `${COMFYUI_BASE_URL}/prompt` (`client_id` UUID), poll `/history/{prompt_id}` toutes les 1,5 s (timeout **6 min** pour une génération mesurée **4-5 min sur GTX 1650**, sous le `receiveTimeout` client de 7 min), retourne l'URL ComfyUI `/view?filename=…&subfolder=…&type=output` + `provider: 'comfyui'`. Négatif, checkpoint, sampler et steps viennent du fichier. Toute défaillance (base vide, injoignable, HTTP ≠ 2xx, `node_errors` de queue, `status_str: 'error'`, timeout) → `ImageServiceUnavailableError` (503 `IMAGE_SERVICE_UNAVAILABLE`) avec logs structurés ; `isAvailable()` ping `/system_stats` (2 s, never throws). **Double origin** : le backend appelle `COMFYUI_BASE_URL` (conteneur → `host.docker.internal:8188`, vérifié 200) mais l'`imageUrl` rendu utilise `COMFYUI_PUBLIC_URL` (`http://localhost:8188`, vide = réutilise la base) car `host.docker.internal` ne se résout pas côté Flutter — documenté dans `env.ts` + `.env.example` (IP LAN + `--listen 0.0.0.0` depuis un appareil).
  - **Chaîne de timeouts + activation live** : `.env` utilisateur = `COMFYUI_BASE_URL=http://host.docker.internal:8188` + `COMFYUI_PUBLIC_URL=http://localhost:8188` ; conteneur recréé par `docker compose up -d api` (`restart` ne recharge **pas** l'env_file) puis `healthy`, vars injectées confirmées. Backend 6 min / app 7 min (`receiveTimeout` du datasource image 2 → 7 min) : sans cela l'app affichait « bientôt disponible » à 2 min alors que ComfyUI continuait. Desktop → l'image charge sur `localhost:8188` ; téléphone → `COMFYUI_PUBLIC_URL` en IP LAN + flag `--listen 0.0.0.0` (Comfy Desktop ≫ Desktop Settings ≫ instance ≫ Startup Arguments).
  - **Qualité du prompt image** : la description envoyée à SDXL combine maintenant `section.description` **et** `keyTopics` (contrat « kind + title + key points » — avant : `description || keyTopics`, donc les points clés disparaissaient si une description existait) ; `buildImagePrompt` préfixé `masterpiece, best quality … depicting exactly the topic: "<titre>"` + suffixe **text-free** (`no text, no words, no letters, no numbers, no captions anywhere`) ; negative du workflow enrichi (`gibberish, unreadable letters, lorem ipsum, fake text, words, captions, labels, digits`) car SDXL invente un faux-titre illisible (observé : « FONATEENTS RESTTOPES » sur une section REST) ; `KIND_PROMPTS` sans promesse de labels (`numbered stages` → `stages connected by arrows`) — **l'image ne doit contenir AUCUN texte**, le contenu diagramme lisible = Mermaid dans le cours (déjà supporté) ; `steps` 30 → **20** dans le workflow (~2-3 min au lieu de 4-5 min sur la GTX 1650). Sortie ComfyUI : `%LOCALAPPDATA%\Comfy-Desktop\ComfyUI-Shared\output\sdxl_simple_*.png` (la tentative app du 14:51 a bien produit `sdxl_simple_00023_.png` mais l'ancien timeout 100 s avait déjà renvoyé 503 → non affichée). **Mise à jour v1.9.2** : ce template n'est plus que le **repli** — les prompts sont désormais réécrits en anglais par le LLM local avant d'être envoyés à SDXL.
  - **Contrats** : `ai-assistant.openapi.yaml` — intro, summary et description de `/ai/courses/sections/image` réécrits (SDXL 512×512, prompt/seed injectés, URL `/view`), `x-status: stub → implemented`, description 503 mise à jour ; `contracts/README.md` (« image stub » → « image ComfyUI SDXL 512×512 »). **redocly EXIT=0** (51 warnings inchangés). Commentaires du port et du use-case alignés.
  - **Qualité** : nouveau `tests/unit/comfyui-image.adapter.test.ts` (11 tests, fetch mocké + `vi.resetModules` pour réévaluer l'env : désactivé→503, corps de queue conforme — latent 512, seed renouvelé, prompt positif/négatif, `client_id` — découplage `COMFYUI_BASE_URL`/`COMFYUI_PUBLIC_URL`, polling avec étape en attente, 400 queue, `node_errors`, erreur history, injoignable, `isAvailable` ×3) ; suite **253/253 vertes (25 fichiers)**, `npm run build` OK (JSON émis), typecheck 0, lint 34 erreurs toutes préexistantes. Front : seul `receiveTimeout` de `generateSectionImage` 2 → 7 min (doc comment alignée, voir `../Frontend/PROJECT_CONTEXT.md`).

- 2026-10-18 — v1.9.2 — **Prompts d'image réécrits par le LLM local (Qwen) au format SDXL anglais** :
  - **Port** `ImagePromptOptimizerPort` (domain) + adapter `LlmImagePromptOptimizer` : réécrit le contenu de section (titre/matière du cours + `title` + `description` + `keyTopics`, souvent français) en paire `{"positive","negative"}` **en anglais** pour le checkpoint `sd_xl_base_1.0.safetensors`, via la gateway LLM existante (`AiGatewayPort.chatCompletion`, `thinking: false`, température 0.3, 400 tokens — chaîne modèle primaire + fallback Qwen `hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1`). System prompt « JSON only » ; `parseOptimizedPrompts` (exporté, testé) nettoie les fences ```` ```json ````, extrait le premier `{…}`, valide présence/longueur des champs puis tronque (positive 1500 / negative 1000 caractères) ; toute erreur → `InternalError` → le use case **replique sur le template déterministe**.
  - **Flux** : `GenerateSectionImageUseCase` charge le cours (IDOR inchangé, désormais utilisé : `course.title`/`course.subject` dans le prompt optimisé) → optimiseur → `imageGenerator.generate({positive, negative, kind})`. `ImageGenerateInput` = `{positive, negative?, kind}` (fini `{title, description}`) ; `buildImagePrompt`/`KIND_PROMPTS` déplacés dans **`domain/image-prompt.ts`** (+ `KIND_STYLE_HINTS` pour l'optimiseur) et ne servent plus que de **repli** (avec `negative` absent → negative workflow par défaut + suffixe anti-gibberish). L'adapter ComfyUI injecte le `positive` tel quel et un `negative` fourni **verbatim** (remplace le défaut, sans suffixe) ; `result.prompt` = positif effectivement envoyé (rendu dans le dialog builder côté app). Nouvelle option de module `imagePromptOptimizer` (DI tests) + wiring `LlmImagePromptOptimizer(gateway)`.
  - **Bénéfice** (avant/après fourni par l'utilisateur) : prompt du type « educational diagram, clean flat vector illustration, labeled nodes, Product Backlog analysis … professional educational design, high quality » + négatif anglais complet, au lieu du template FR mêlé — diagrammes SDXL nettement plus propres et cohérents.
  - **Règle « zéro texte » (consigne utilisateur)** : l'image ne doit contenir **aucune lettre, aucun mot**. Le system prompt impose désormais de distiller la section en **UNE scène visuelle concrète** en anglais (ex. « Introduction au Scrum » → *two colleagues discussing in front of a blank whiteboard in a bright modern workspace, sticky notes and simple arrows…* — few-shot inclus) et interdit tout terme textuel dans le positif (`labeled nodes`, `clear typography`, titres, charts, écrans) ; le négatif commence par toute la famille du texte (`text, words, letters, numbers, typography, captions, labels, writing, watermark, signage…`). `KIND_STYLE_HINTS` et `KIND_PROMPTS` (repli) reformulés en **wordless** (formes/flèches/objets seulement) ; le contenu lisible reste Mermaid dans le cours.
  - **Contrats** : intro, summary et description de `/ai/courses/sections/image` réécrits (étape LLM, fallback template, origine `prompt`) ; description du champ `prompt` = « positive SDXL prompt actually sent » ; `contracts/README.md` « image stub » → « SDXL section illustration with LLM-optimized prompts ». **redocly EXIT=0** (51 warnings inchangés).
  - **Qualité** : nouveau `tests/unit/llm-image-prompt-optimizer.test.ts` (11 tests : JSON nu/fences/prose, JSON absent, champs manquants, cap, message utilisateur cours+section+points clés + `thinking: false`, propagation d'erreur gateway et de réponse malformée) ; `comfyui-image.adapter.test.ts` adapté au nouveau `{positive, negative?}` (négatif fourni verbatim sans suffixe / défaut + gibberish si absent) → 12 tests ; `section-build.use-cases.test.ts` : appel optimiseur avec les données cours/section + repli template sur échec. Suite **264/264 vertes (26 fichiers)**, typecheck 0, lint 34 erreurs toutes préexistantes. Aucune modification Flutter (le champ `prompt` du 200 était déjà affiché).

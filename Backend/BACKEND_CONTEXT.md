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
| IA / RAG | Port `AiGatewayPort` → service IA **auto-hébergé** (RG27 : aucune API LLM tierce) | | Sprint 2/4 |
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
| `pino-pretty` (dev) | Logs lisibles en local |
| `argon2` | Hachage sécurisé des mots de passe (Argon2id, Sprint 1) |
| `jose` | Gestion et vérification JWT ESM sans dépendance native (Sprint 1) |

**Volontairement PAS installés maintenant** : `ioredis` / `rate-limit-redis`, `bullmq`, `socket.io`, `@aws-sdk/*`, `multer`, libs OpenAPI, `husky`, plugins de frontières ESLint. Chacun arrive avec la feature qui en a besoin.

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
| 1 | UC8 Auth & profil, UC6 Groupes-classes (RG1-RG3) | 🟡 En cours (Auth endpoints, OTP email, blocage 5 min, tokens rotatifs terminés) |
| 2 | UC1 Cours + upload/extraction PDF + LLM local + validation prof (RG4-RG5) | ⬜ |
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
- [ ] Validation/génération automatique des contrats (lint OpenAPI, client Dart pour Dio/Retrofit) — quand le front branche l'API
- [ ] Redis (rate limit partagé / jobs) — quand 2+ instances
- [ ] Moteur S3 (SeaweedFS / Garage / RustFS / managé) — Sprint 2
- [ ] Fournisseur visio (LiveKit vs Jitsi) — Sprint 3
- [ ] Modèle d'embedding → dimension du `vector(n)` — Sprint 2/4
- [ ] Durées de rétention (vidéos, snapshots) — RG14/RG21
- [ ] Énoncés de RG2, RG3, RG5, RG10, RG13, RG24 + correction de la numérotation RG25/RG27
- [ ] Fournisseur e-mail/push (adaptateur console dev actuellement en place)

**Journal**
- 2026-10-05 — v1.0.0 — Création du contexte backend (périmètre : initialisation).
- 2026-10-05 — v1.1.0 — Monorepo (`front/ backend/ docs/ contracts/`) ; ajout des contrats OpenAPI contract-first (§5.1).
- 2026-10-05 — v1.2.0 — Initialisation backend complète (Sprint 0) : scaffold Express 5 / Node 24 / TS strict, Dockerfile multi-stage, docker-compose avec healthchecks (`api` et `db` postgres17+pgvector), shared kernel (env fail-fast, Pino avec redaction, AppError, validation Zod, pagination offset/cursor, rate limiter), schéma Prisma 7 avec User & extension vector, module de référence Health (Clean Architecture 4 couches), contrats OpenAPI 3.1 (`common.yaml`, `health.openapi.yaml`), suite de 46 tests unitaires et d'intégration 100% verts, README technique.
- 2026-10-06 — v1.3.0 — Implémentation complète du système d'authentification (Sprint 1, UC8) : 9 endpoints REST (`/auth/*`), schéma relationnel complet (`User`, `RefreshToken`, `EmailVerificationCode`, `PasswordResetCode`), hachage Argon2id, tokens rotatifs avec détection de réutilisation, OTP par email (6 chiffres, 15 min, max 3 tentatives), blocage temporaire automatique de 5 minutes après 3 tentatives de mot de passe erronées (HTTP 423 `AUTH_ACCOUNT_LOCKED`), Zod strict, contrat OpenAPI 3.1 `contracts/auth.openapi.yaml`, 14 nouveaux tests unitaires/intégration (60/60 tests au total verts).

---

*Dernière mise à jour : 2026-10-06 · Version : 1.3.0*

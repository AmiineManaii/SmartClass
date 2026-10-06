# SmartClass API Contracts

> **Contract-first API documentation**: one hand-written OpenAPI 3.1 YAML file per module.
> These files describe exactly what each endpoint **requires** and **returns** — the Flutter app reads this instead of digging through backend code.

## Folder Layout

```
contracts/
├── README.md                  # this file
├── common.yaml                # shared components (errors, pagination, security)
├── health.openapi.yaml        # health module (implemented)
└── <module>.openapi.yaml      # one per module, created when that module is built
```

## Rules

1. **One module = one file** named `<module>.openapi.yaml` (kebab-case), matching the module folder in `backend/src/modules/<name>/`.
2. **Contract-first**: write or update the contract *before* implementing or changing an endpoint, then code to match it.
3. **Same task = contract + Zod schema + tests + README index.** A contract that diverges from the code is a bug.
4. Every operation has: unique camelCase `operationId`, `tags`, `summary`, `description` (citing business rules RG), `security`, a `requestBody` with required fields/types/constraints, `additionalProperties: false`, at least one `example`, and **every possible response** (success + each error with its stable `error.code`).
5. Shared pieces live only in `common.yaml` and are referenced with `$ref: './common.yaml#/components/...'` — never copied.
6. Field names and enum values = the real JSON ones (camelCase, English enums).
7. `servers`: `/api/v1` for modules, except `health.openapi.yaml` which uses `/` (health routes are outside `/api/v1`).
8. Each operation carries `x-status: planned | implemented`, mirrored in the index table below.

## Contract-First Workflow

1. **Propose** the contract (new/updated YAML).
2. **Review** with the team.
3. **Implement** the backend to match the contract.
4. **Mark** `x-status: implemented` and update this README.
5. If the frontend developer finds something missing (a field, an error, an endpoint), it is **added to the contract first** (`x-status: planned`), then the backend implements it.

## One-Off Validation

```bash
npx --yes @redocly/cli@latest lint contracts/*.yaml
```

> This command is **not** added to `package.json`. Use it ad-hoc to validate the contracts.

## Index Table

| Module | File | Base Path | Status |
|--------|------|-----------|--------|
| health | `health.openapi.yaml` | `/` | ✅ implemented |
| auth | `auth.openapi.yaml` | `/api/v1/auth` | ✅ implemented |
| users | not created yet | `/api/v1/users` | 📋 planned |
| groups | not created yet | `/api/v1/groups` | 📋 planned |
| courses | not created yet | `/api/v1/courses` | 📋 planned |
| exams | not created yet | `/api/v1/exams` | 📋 planned |
| videoconference | not created yet | `/api/v1/videoconference` | 📋 planned |
| collaboration | not created yet | `/api/v1/collaboration` | 📋 planned |
| ai-assistant | not created yet | `/api/v1/ai-assistant` | 📋 planned |
| notifications | not created yet | `/api/v1/notifications` | 📋 planned |

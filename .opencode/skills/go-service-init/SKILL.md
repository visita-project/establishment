---
name: go-service-init
description: Initialize a new Go service project with a mise-managed toolchain and interview-selected tooling. Use this skill when the user asks to create, scaffold, bootstrap, or initialize a new Go service or Go project from scratch.
compatibility: Requires git and mise-en-place (mise) installed
---

# Go Service Init

Initialize a Go service with a mise-managed toolchain. Base tools (go, golangci-lint) are always included; additional tooling is added only when the user selects it in the interview.

## Rules

- **Never guess.** No git remote, ambiguous answer, missing tool backend → ask the user. Do not invent module paths, versions, or config.
- **All tool invocations go through mise tasks.** Once `mise.toml` exists, run Go commands via `mise exec -- <cmd>` so the pinned toolchain is used.
- **Tool flows create their own directories** (`api/`, `gen/`, `migrations/`). The base scaffold does not pre-create them.

## Workflow

- [ ] 1. Preconditions — git repo + remote
- [ ] 2. Interview — capabilities + binary name
- [ ] 3. Base scaffold — follow `references/base-scaffold.md`
- [ ] 4. Tool flows — only selected capabilities, in order
- [ ] 5. Verification — build, lint, and all `gen:*` tasks pass
- [ ] 6. Report — what was created, next steps

### 1. Preconditions

1. Verify inside a git repo: `git rev-parse --is-inside-work-tree`. If not → ask the user whether to `git init` and configure a remote first.
2. Get the remote: `git remote get-url origin`. If no remote exists → ask the user for the module path (e.g. `github.com/org/repo`). Never invent one.

### 2. Interview

Ask **one multi-select question**: *"Which capabilities will the service have?"* Each option maps to a tool flow:

| Option | Tools added | Flow reference (load only if selected) |
|---|---|---|
| HTTP API | ogen | `references/ogen.md` |
| gRPC API | buf | `references/buf.md` |
| PostgreSQL storage | sqlc + golang-migrate | `references/postgres.md` |
| Dependency injection | wire | `references/wire.md` |
| Test mocks | mockgen | `references/mockgen.md` |
| Struct converters | goverter | `references/goverter.md` |
| Domain enums | go-enum | `references/go-enum.md` |
| Docker | Dockerfile + docker-compose | `references/docker.md` |

Also ask for the **binary name** (default: `serverd`).

If the user is unsure about an option, recommend: goverter when any codegen tool (ogen/buf/sqlc) is selected; wire for any service with more than one layer.

### 3. Base scaffold

Follow `references/base-scaffold.md` step by step. Return here when its gate passes.

### 4. Tool flows

For each selected capability, follow its reference file in this order:

`ogen` → `buf` → `postgres` → `wire` → `goverter` → `go-enum` → `mockgen` → `docker`

(Docker runs last: `docker-compose.yml` aggregates services implied by earlier selections, e.g. PostgreSQL.)

### 5. Verification

Run and fix until all pass:

```bash
mise install
mise run build
mise run lint
```

Plus every `gen:*` / migration task added by tool flows.

### 6. Report

Summarize: module path, binary name, selected tools with their versions, created files, and suggested next steps (e.g. "define your first endpoint in `api/openapi/` then run `mise run gen:oapi`").

## Gotchas

- Run `mise trust` immediately after adding `[env]` to `mise.toml` — every mise command fails non-interactively until you do.

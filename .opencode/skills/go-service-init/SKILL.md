---
name: go-service-init
description: Initialize a Go service skeleton from scratch — go module, cmd/serverd main, mise-en-place, Dockerfile, docker-compose, and optional API/storage/DI tooling (HTTP/ogen, gRPC/buf, PostgreSQL/sqlc, Redis, Wire, goverter, go-enum, mockgen, golangci-lint). Use when the user wants to scaffold, bootstrap, or initialize a new Go service project.
license: MIT
metadata:
  author: visita-project
  version: "1.0"
---

# Initialize a Go service skeleton

This skill scaffolds a new Go service following the project's standard layered
structure (`cmd/`, `internal/`, `gen/`) and standard toolchain (mise-managed).
It does NOT write business logic — it lays down directories, config, and
tooling so development can start immediately.

## When NOT to use

- The user wants to add a feature to an already-initialized service (use normal
  development; only re-run this skill for a brand-new service).
- The user explicitly wants a non-Go project.

## Prerequisites

- The target directory is **empty** (no `go.mod`) OR partially initialized.
  Detect existing files and never overwrite destructively (see Guardrails).
- `mise` is expected to be the tool runner. All generated task commands are
  mise tasks, not raw tool calls.

## Inputs to gather

Ask the user up front using the **question** tool. Run these as **one** combined
`question` call with multiple questions so the user answers in a single pass.

1. **Module path** — the go module path, MUST follow git repo naming
   (`github.com/<owner>/<repo>`). Derive a default from `git remote get-url
   origin` if the target is a git repo; otherwise default to
   `github.com/{{owner}}/{{dir-name}}` and let the user confirm/edit.
2. **Service name** — short kebab-case name (used for binary labels, db name,
   proto package). Default to the last path segment of the module path.
3. **HTTP API (ogen)?** — yes/no.
4. **gRPC API (buf)?** — yes/no.
5. **PostgreSQL storage (sqlc + golang-migrate)?** — yes/no.
6. **Redis?** — yes/no.
7. **Wire (DI)?** — yes/no.
8. **goverter?** yes/no.
9. **go-enum?** yes/no.
10. **mockgen (uber-go/mock)?** yes/no.
11. **golangci-lint config?** yes/no (default yes).

golangci-lint and mise itself are always set up regardless of answers; the
question only controls whether the `.golangci.yaml` config file is written.

If the user has already provided the module path / service name / tool list in
their message, skip the corresponding questions and use what they gave.

## Steps

Track progress with the **TodoWrite** tool.

1. **Resolve target directory and existing state.**
   - The directory to initialize is the current working directory unless the
     user named a path. Verify it exists; create it if named and missing.
   - List its contents. If `go.mod` exists, read it and skip step 2 (module
     already initialized) — only patch the path if it differs from the user's
     requested module path.
   - If the directory is non-empty in a way that conflicts (e.g. existing
     `cmd/`, `mise.toml`), ask before overwriting.

2. **Initialize the go module (git naming convention).**
   ```bash
   go mod init "<module-path>"
   ```
   The module path MUST follow `github.com/<owner>/<repo>` (or another git
   host following the same `<host>/<owner>/<repo>` convention). Lowercase,
   no spaces.

3. **Create the entry point.**
   - Create `cmd/serverd/main.go` from `assets/main.go.tmpl` (empty `main`).
   - `serverd` (daemon suffix per Unix convention) is the default binary name.
     If the user gives a different binary name, use that subdir instead.

4. **Create mise-en-place files.**
   - Determine the latest stable Go version: `mise ls-remote go | grep -E '^[0-9]' |
     tail` and pick the newest non-prerelease. Substitute into `{{GO_VERSION}}`.
   - Write `mise.toml` from `assets/mise.toml.tmpl` (substitute `{{GO_VERSION}}`).
     If `mise.toml` already exists, merge: keep existing `[tools]`/`[env]`, append
     missing tasks. Do not clobber.
   - Write `mise.local.toml` from `assets/mise.local.toml.tmpl` only if absent.
   - Create/append `.gitignore` from `assets/gitignore.tmpl` and ensure
     `mise.local.toml` is ignored (add the line if an existing `.gitignore` lacks it).

5. **Create the Dockerfile** from `assets/Dockerfile.tmpl` (substitute
   `{{GO_VERSION}}`). Multi-stage, distroless final image.

6. **Create docker-compose.yml** from `assets/docker-compose.yml.tmpl`.
   Substitute `{{SERVICE_NAME}}`. Leave the `postgres` and `redis` blocks
   commented; the PostgreSQL and Redis tool steps uncomment the relevant ones
   and fill `{{POSTGRES_VERSION}}` / `{{REDIS_VERSION}}` with the latest stable
   alpine majors (verify before pinning).

7. **Apply each selected tool.**
   Load `references/tool-init.md` and apply ONLY the sections for tools the
   user selected. For each:
   - Append its `[tools]` entry(ies) and `[tasks]` block(s) to `mise.toml`.
   - Create any config/spec/proto/migration files from the named templates in
     `assets/`, substituting all placeholders.
   - Create `gen/<tool>/.gitkeep` placeholder files so output directories exist.
   - For the default binary `serverd`, also create `internal/config/config.go`
     with an empty `type Config struct{}` package `config` so the Wire
     template's import resolves IF Wire is selected (the template imports
     `internal/config`).

8. **Verify the skeleton.**
   - Run `mise install` (installs pinned tools).
   - Run `go build ./...` — it MUST compile (the skeleton is empty but valid).
   - If `mise` or a tool is unavailable in the environment, skip the failing
     command but report it; do not block the file generation.
   - Generate any generated artifacts the user wants now? **No** — only scaffold
     config. The user runs `mise gen:*` tasks themselves after `mise install`.

9. **Report.**
   Summarize: module path, binary, files created, tools enabled, and the exact
   mise commands to run next, e.g.:
   ```
   mise install
   [docker compose up -d]        # if PostgreSQL/Redis selected
   [mise migrate:up]             # if PostgreSQL selected
   mise gen:oapi / gen:proto / gen:sqlc / gen:wire / gen:conv / gen:enum / gen:mocks  # selected ones
   mise lint && mise test && mise build
   ```

## Placeholder substitution

Templates use `{{PLACEHOLDER}}` tokens (case-sensitive). The set:
- `{{GO_VERSION}}` — newest stable Go (e.g. `1.26.4`).
- `{{MODULE_PATH}}` — module path without surrounding quotes.
- `{{SERVICE_NAME}}` — kebab-case, e.g. `order` (also used as DB name).
- `{{SERVICE_NAME_LOWER}}` — lowercase no separators, e.g. `order`.
- `{{SERVICE_TITLE}}` — Title Case, e.g. `Order`.
- `{{SERVICE_TITLE_CAMEL}}` — CamelCase Go identifier, e.g. `Order`.
- `{{POSTGRES_VERSION}}`, `{{REDIS_VERSION}}` — alpine major tags.

Substitute by editing files (do not leave any `{{...}}` token in the output).

## Guardrails

- **Non-destructive:** never overwrite an existing file without confirming.
  Merge `mise.toml`/`.gitignore` rather than rewriting. Skip `go mod init` if
  `go.mod` exists.
- **Empty stubs only:** do NOT add business logic, HTTP handlers, or fake
  entities. The skeleton is directories + config + an empty `main`.
- **Kafka is out of scope** for this skill (added later); do not scaffold Kafka
  producers/consumers even if asked — note it is deferred.
- **No inlining:** file contents come from `assets/*.tmpl`, not from strings in
  this file. The empty `main` lives in `assets/main.go.tmpl`.
- **Module path must be lowercase** and follow the git host convention.
- **Latest versions:** prefer `mise ls-remote <tool>` for mise-managed tools and
  verifying Docker image tags over guessing. Don't fabricate version numbers.
- **Keep it minimal:** only create directories and files the selected tools need.
  Do not pre-create `internal/app`, `internal/core`, etc. unless a selected tool
  requires it (only `internal/config` for Wire).
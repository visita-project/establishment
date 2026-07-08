# Per-tool initialization reference

Each section below describes how to initialize ONE tool the user selected. Apply
only the sections for selected tools. Append `[tools]` entries and `[tasks]`
blocks into the existing `mise.toml` (do not rewrite it). All file paths are
relative to the **target project root** (the directory being initialized), not
the skill directory.

Placeholders to substitute everywhere (case-sensitive):
- `{{MODULE_PATH}}` — full go module path, e.g. `github.com/visita-project/order`.
- `{{SERVICE_NAME}}` — short service name, kebab/lowercase, e.g. `order`.
- `{{SERVICE_NAME_LOWER}}` — lowercase, no separators, e.g. `order`.
- `{{SERVICE_TITLE}}` — Title Case for docs, e.g. `Order`.
- `{{SERVICE_TITLE_CAMEL}}` — CamelCase for Go identifiers, e.g. `Order`.

Before pinning a tool version run `mise ls-remote <tool>` and use the newest
**stable** version (strip pre-release suffixes unless the tool only publishes
those). For Docker images, verify `{{POSTGRES_VERSION}}` / `{{REDIS_VERSION}}`
are the current `alpine`-tagged majors at the time of execution.

---

## HTTP API — ogen

Generate type-safe Go HTTP server stubs and models from an OpenAPI spec.

1. Add to `mise.toml` `[tools]`:
   ```toml
   ogen = "latest"
   ```
2. Add to `mise.toml` tasks:
   ```toml
   [tasks."gen:oapi"]
   run = "ogen -target gen/oapi api/openapi/api.yaml"
   ```
3. Create `api/openapi/api.yaml` from `assets/openapi.yaml.tmpl`.
4. Create `.ogen.yml` at project root from `assets/.ogen.yml.tmpl`.
5. Create empty `gen/oapi/.gitkeep` so the output dir is tracked before first
   generation.
6. Tell the user: run `mise gen:oapi` after `mise install` to generate stubs.

---

## gRPC API — buf

Generate Go protobuf messages and gRPC service stubs from `.proto` files.

1. Add to `mise.toml` `[tools]`:
   ```toml
   buf = "latest"
   protoc-gen-go = "latest"
   protoc-gen-go-grpc = "latest"
   ```
   > NOTE: `protoc-gen-go` and `protoc-gen-go-grpc` are used by the remote buf
   > plugins only when not using remote; keep them for `go install` fallback. If
   > `mise ls-remote protoc-gen-go` reports nothing, install via a bootstrap task:
   > `go install google.golang.org/protobuf/cmd/protoc-gen-go@latest`.
2. Add to `mise.toml` tasks:
   ```toml
   [tasks."gen:proto"]
   run = "buf generate"
   ```
3. Create `api/proto/buf.yaml` directory: actually create `buf.yaml` at project
   ROOT from `assets/buf.yaml.tmpl`, and `buf.gen.yaml` at project root from
   `assets/buf.gen.yaml.tmpl`.
4. Create `api/proto/{{SERVICE_NAME_LOWER}}/v1/{{SERVICE_NAME_LOWER}}.proto`
   from `assets/service.proto.tmpl`.
5. Create empty `gen/proto/.gitkeep`.
6. Tell the user: run `mise gen:proto` after `mise install`.

---

## PostgreSQL storage — sqlc + golang-migrate

1. Add to `mise.toml` `[tools]`:
   ```toml
   sqlc = "latest"
   golang-migrate = "latest"
   ```
2. Add to `mise.toml` tasks:
   ```toml
   [tasks."gen:sqlc"]
   run = "sqlc generate"

   [tasks."migrate:up"]
   run = "migrate -path migrations -database \"$DATABASE_URL\" up"

   [tasks."migrate:down"]
   run = "migrate -path migrations -database \"$DATABASE_URL\" down 1"

   [tasks."migrate:new"]
   run = "migrate create -dir migrations -ext sql -seq"
   ```
   (`migrate:new` takes an extra arg — the migration name — e.g.
   `mise migrate:new -- add_users_table`.)
3. Create `sqlc.yaml` at project root from `assets/sqlc.yaml.tmpl`.
4. Create `migrations/` directory and place an initial migration from
   `assets/migration.sql.tmpl`. Name it `000001_init.up.sql` and `000001_init.down.sql`
   if the user wants up/down split files; otherwise keep the single `-- +migrate Up`
   style for golang-migrate, which actually uses separate up/down files. Use the
   separate-file convention: create `migrations/000001_init.up.sql` and
   `migrations/000001_init.down.sql`.
5. Create `internal/infra/storage/postgres/queries/` directory and a placeholder
   query file `queries_placeholder.sql` from `assets/queries_placeholder.sql.tmpl`.
6. Create empty `gen/sqlc/.gitkeep`.
7. Uncomment the `postgres` service in `docker-compose.yml` and set
   `{{POSTGRES_VERSION}}` to the latest stable alpine major (e.g. `17`).
8. Add to `mise.local.toml` `[env]`:
   ```toml
   DATABASE_URL = "postgres://postgres:postgres@localhost:5432/{{SERVICE_NAME}}?sslmode=disable"
   ```
9. Tell the user: start deps with `docker compose up -d`, then
   `mise migrate:up` and `mise gen:sqlc`.

---

## Redis

Redis needs no codegen for the skeleton; it only adds a local service.

1. Uncomment the `redis` block and `redis_data` volume in `docker-compose.yml`.
2. Set `{{REDIS_VERSION}}` to the latest stable alpine major (e.g. `7`).
3. Tell the user the Redis client package will be added in `internal/infra/storage/redis/`
   when the first cache/client is implemented.

---

## Wire (goforj/wire fork)

Compile-time dependency injection.

1. Add to `mise.toml` `[tools]`:
   ```toml
   wire = "latest"
   ```
   > NOTE: the goforj fork installs as the `wire` command. If
   > `mise ls-remote wire` is empty, add a bootstrap task:
   > `go install github.com/goforj/wire/cmd/wire@latest`.
2. Add to `mise.toml` tasks:
   ```toml
   [tasks."gen:wire"]
   run = "wire ./cmd/serverd/..."
   ```
3. Create `cmd/serverd/wire.go` from `assets/wire.go.tmpl`. The build tag keeps
   it out of normal builds; `mise gen:wire` produces `wire_gen.go`.
4. Add `go.uber.org/mock` import note: Wire uses `wire.Build`; the template's
   sample `wireApp` is commented out so the project still compiles. Uncomment and
   fill providers as layers are implemented.

---

## goverter

Type-safe struct-to-struct converters at layer boundaries.

1. Add to `mise.toml` `[tools]`:
   ```toml
   goverter = "latest"
   ```
2. Add to `mise.toml` tasks:
   ```toml
   [tasks."gen:conv"]
   run = "goverter gen ./..."
   ```
3. No skeleton files are created; converter interfaces live in `conv/`
   sub-packages (e.g. `internal/transport/http/conv/`) as those layers are built.

---

## go-enum

Type-safe enum implementations from annotated Go types.

1. Add to `mise.toml` `[tools]`:
   ```toml
   go-enum = "latest"
   ```
2. The base `mise.toml` template already includes a `gen:enum` task:
   ```toml
   [tasks."gen:enum"]
   run = "go generate ./internal/core/..."
   ```
   Confirm it is present; add if missing.
3. No skeleton files are created; enums are declared in `internal/core/...`
   with `//go:generate go-enum --marshal --names --nocase --ptr -f $GOFILE`.

---

## mockgen (uber-go/mock)

1. Add to `mise.toml` `[tools]`:
   ```toml
   mockgen = "latest"
   ```
   > NOTE: installs the `mockgen` binary from `go.uber.org/mock`. If
   > `mise ls-remote mockgen` is empty, add a bootstrap task:
   > `go install go.uber.org/mock/mockgen@latest`.
2. The base `mise.toml` template already includes a `gen:mocks` task:
   ```toml
   [tasks."gen:mocks"]
   run = "go generate ./..."
   ```
   Confirm it is present; add if missing.
3. No skeleton files; mocks are generated via `//go:generate mockgen ...`
   directives placed in source files as interfaces appear.

---

## golangci-lint

1. Create `.golangci.yaml` at project root from `assets/.golangci.yaml.tmpl`.
2. The base `mise.toml` template already pins `golangci-lint = "latest"` and
   the `lint` task. Confirm both are present.
3. After all selected tools are set up, run `mise lint` to verify the skeleton
   compiles and lints clean.
# Tools Reference

This document describes every tool used in Go service projects, how it is configured, and how to invoke it. AI agents MUST follow these specifications when generating, modifying, or running code.

---

## mise-en-place

**Purpose:** Tool version management, task runner, and environment variable management. Central orchestrator for tool invocations.

**Configuration files:**
- `mise.toml` — defines tool versions, tasks, and environment variables.
- `mise.local.toml` — local overrides, added to `.gitignore`. Used for local-only environment variables (database credentials, API keys, etc.).

**What it manages:**
- Tool versions (Go, sqlc, ogen, buf, golangci-lint, mockgen, wire, goverter, golang-migrate, etc.) via the `[tools]` section.
- Task definitions (build, lint, test, generate, migrate, etc.) via the `[tasks]` section.
- Environment variables via the `[env]` section.

**Usage pattern:** All tool invocations are wrapped in mise tasks so commands are simplified and reproducible. Example: instead of running `sqlc generate` directly, a mise task `generate:sqlc` wraps it.

---

## ogen

**Purpose:** Generate type-safe Go HTTP server stubs, client code, and models from an OpenAPI specification. Follows API-first development.

**Input:** OpenAPI spec files located in `api/openapi/`.

**Output:** Generated Go code goes to `internal/gen/oapi/`.

**Configuration file:** `.ogen.yml` at project root. Defines input spec path, output target directory, and generation options.

**Generated artifacts:** Server interfaces, request/response types, routing.

---

## buf

**Purpose:** Protobuf linting and Go code generation from `.proto` files. Used ONLY for linting and code generation — no Buf Schema Registry, no custom buf plugins.

**Input:** `.proto` files located in `api/proto/`.

**Output:** Generated Go protobuf and gRPC code goes to `internal/gen/proto/`.

**Configuration files:**
- `buf.yaml` — module configuration (module name, dependencies, lint/breaking rules).
- `buf.gen.yaml` — code generation configuration. Specifies which protoc plugins to run and where output goes.

**Protoc plugins used (standard Google plugins only):**
- `protoc-gen-go` — generates `.pb.go` files (protobuf message types).
- `protoc-gen-go-grpc` — generates `_grpc.pb.go` files (gRPC service stubs).

---

## sqlc

**Purpose:** Generate type-safe Go data access code from SQL query files. Writes raw SQL, gets generated structs and query functions.

**Repository:** https://github.com/sqlc-dev/sqlc

**Input:** SQL query files (`.sql`) located in a `queries/` subdirectory under store package (e.g., `internal/infra/storage/postgres/queries/`).

**Output:** Generated Go code goes to `internal/gen/sqlc/`.

**Configuration file:** `sqlc.yaml` at project root. Defines:
- Database engine (postgresql).
- Schema path (migrations directory).
- Query file paths.
- Output package and directory (`internal/gen/sqlc/`).
- Go package name and pgx driver override.

---

## golang-migrate

**Purpose:** Database schema migration management. Applies versioned SQL migration files to the database.

**Migration files:** Located in `migrations/` at project root.

**Database driver:** PostgreSQL via pgx.

---

## golangci-lint

**Purpose:** Go linter aggregator. Runs multiple linters in a single pass.

**Configuration file:** `.golangci.yaml` at project root. Defines enabled linters, exclusion rules, and per-linter settings.

---

## uber-go/mock (mockgen)

**Purpose:** Generate mock implementations of Go interfaces for testing. Fork of Google's gomock maintained by Uber.

**Usage pattern:** Mocks are generated via `//go:generate` directives placed in Go source files. The directive invokes `mockgen` targeting a specific interface.

**Output location:** Mocks are stored in a `<package>test` sub-package. For example, interfaces in `internal/app/order/` have their mocks generated into `internal/app/order/ordertest/`.

**Example directive:**
```go
//go:generate mockgen -source=lifecycle.go -destination=ordertest/lifecycle_mock.go -package=ordertest
```

**Generated files:** `<name>_mock.go` files inside the `<package>test/` sub-directory (e.g., `ordertest/lifecycle_mock.go`).

---

## Wire (goforj/wire fork)

**Purpose:** Compile-time dependency injection. Generates wiring code that connects all layers (storage, messaging, app, transport).

**File placement:** `wire.go` files live in `cmd/<binary>/` alongside `main.go`.

**Generated output:** `wire_gen.go` in the same directory as `wire.go`. Contains the real initialization function with all dependencies wired.

---

## goverter

**Purpose:** Generate type-safe struct-to-struct conversion code. Eliminates hand-written mapping boilerplate at layer boundaries.

**Usage scope:** Used at two conversion boundaries:
1. **Transport → App:** Convert generated transport structs (from ogen/buf) to app layer DTOs.
2. **Infra → App:** Convert storage structs (from sqlc/pgx) to domain structs.

**Converter interface location:** Converter interfaces are placed in a `conv/` sub-package within the corresponding transport type package or storage package, e.g.:
- `internal/transport/http/conv/` — HTTP transport converters.
- `internal/transport/grpc/conv/` — gRPC transport converters.
- `internal/infra/storage/postgres/conv/` — PostgreSQL storage converters.

**Configuration:** Comment-based directives on converter interfaces. No separate config file.

**Example directive:**
```go
// goverter:converter
type OrderConverter interface {
    // goverter:map ID OrderID
    ToDomain(source gen.sqlc.OrderRow) order.Order
}
```

**Generated output:** `ConverterImpl` structs generated in the same `conv/` package as the converter interfaces.

---

## Docker

**Purpose:** Containerization for the application binary and local development dependencies.

**Files:**
- `Dockerfile` — multi-stage build for the Go binary. Final stage is a minimal image (e.g., `scratch` or `alpine`).
- `docker-compose.yml` — defines local development dependencies (PostgreSQL, Redis, Kafka, etc.) with appropriate ports and volumes.

**Usage:** `docker-compose up` starts local dependencies. The application binary is run locally via mise tasks, connecting to Docker services.

---

## Tool Invocation Summary

All tools are invoked through mise tasks defined in `mise.toml`. The standard task set:

| Task | Command | Purpose |
|------|---------|---------|
| `generate:oapi` | `ogen -target internal/gen/oapi api/openapi/<spec>.yaml` | Generate HTTP stubs from OpenAPI |
| `generate:proto` | `buf generate` | Generate protobuf/gRPC code |
| `generate:sql` | `sqlc generate` | Generate data access code |
| `generate:mocks` | `go generate ./...` | Generate test mocks |
| `generate:wire` | `wire ./cmd/serverd/...` | Generate dependency wiring |
| `generate:converters` | `goverter gen ./...` | Generate struct converters |
| `lint` | `golangci-lint run ./...` | Run linters |
| `test` | `go test ./...` | Run tests |
| `migrate:up` | `migrate -path migrations -database $DATABASE_URL up` | Apply migrations |
| `migrate:down` | `migrate -path migrations -database $DATABASE_URL down` | Rollback migrations |
| `build` | `go build ./cmd/serverd/` | Build binary |

---

## Directory Layout for Tool Artifacts

```
api/
├── openapi/          # OpenAPI spec files (ogen input)
└── proto/            # Protobuf files (buf input)
migrations/           # SQL migration files (golang-migrate)
internal/
├── gen/
│   ├── oapi/         # ogen generated code
│   ├── proto/        # buf generated protobuf/gRPC code
│   └── sqlc/         # sqlc generated data access code
├── infra/storage/postgres/queries/  # .sql query files (sqlc input)
buf.yaml              # buf module config
buf.gen.yaml          # buf generation config
sqlc.yaml             # sqlc generation config
.ogen.yml             # ogen generation config
.golangci.yaml        # linter config
mise.toml             # tool versions + tasks (committed)
mise.local.toml       # local env overrides (gitignored)
Dockerfile            # app container build
docker-compose.yml    # local dev dependencies
```

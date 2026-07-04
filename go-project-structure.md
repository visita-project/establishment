# Go Project Structure

This document defines the standard Go project structure for all services in this project. AI agents and developers MUST follow this structure when implementing, generating, or modifying code.

## Overview

The project follows a layered architecture inspired by Domain-Driven Design (DDD) and Clean Architecture. Dependencies flow inward toward the domain core. Infrastructure implementations satisfy interfaces defined by the application layer (dependency inversion).

### Dependency Flow

```
cmd/  →  transport/  →  app/  →  core/
  ↓           ↓           ↓        ↓
storage/  messaging/  gen/    platform/
```

- `cmd` wires all layers together (dependency injection).
- `transport` calls `app` use cases.
- `app` uses `core` domain objects and defines interfaces for `storage` and `messaging`.
- `storage` and `messaging` implement interfaces defined in `app`.
- `platform` can be imported by any layer **except `core`**.
- `gen` is imported by `transport`.
- **`core` MUST NOT import `platform` packages.**

### Naming Rules

- **No generic suffixes**: Never use `Service`, `Repository`, `Manager`, `Handler` as struct name suffixes. Names must describe what the struct does (e.g., `Lifecycle`, `Querier`, `Uploader`).
- **Storage interfaces**: Use `Store` (not `Storer`, not `Repository`). Example: `OrderStore`.
- **File naming**: Files are named by the role they play: `lifecycle.go`, `querier.go`, `uploader.go`, `order_handler.go`, `order_store.go`.

---

## Directory Structure

Below is the reference file tree for an order service project:

```
cmd/
├── serverd/
│    └── main.go
internal/
├── config/
│   └── config.go
├── app/
│   ├── order/
│   │   ├── lifecycle.go
│   │   └── querier.go
│   └── product/
│       ├── uploader.go
│       └── querier.go
├── core/
│   ├── errors/
│   │   └── errors.go
│   ├── order/
│   │   ├── status/
│   │   │   └── status.go
│   │   ├── order.go
│   │   └── item.go
│   ├── product/
│   │   └── product.go
│   └── quantity/
│       └── quantity.go
├── platform/
│   ├── logging/
│   │   └── logger.go
│   └── auth/
│       ├── jwt.go
│       ├── verifier.go
│       └── issuer.go
├── gen/
│   ├── oapi/
│   │   └── order_ogen_gen.go
│   └── proto/
│       └── order/
│           └── v1/
│               ├── order.pb.go
│               └── order_grpc.pb.go
├── transport/
│   ├── http/
│   │   ├── middleware/
│   │   │   └── auth.go
│   │   ├── product_handler.go
│   │   └── order_handler.go
│   ├── grpc/
│   │   ├── interceptors/
│   │   │   └── auth.go
│   │   └── order_handler.go
│   └── kafka/
│       └── order_handler.go
├── messaging/
│   └── kafka/
│       └── product_producer.go
├── storage/
│   ├── postgres/
│   │   ├── order_store.go
│   │   └── product_store.go
│   ├── redis/
│   │   └── product.go
│   └── memory/
│       └── product_lru_cache.go
go.mod
go.sum
```

---

## Package Descriptions

### `cmd/` — Entry Points

Each subdirectory is a compiled binary. Multiple binaries per repository are allowed.

- **Daemon binaries** use the `d` suffix following Unix convention (e.g., `serverd`, `workerd`).
- **Non-daemon binaries** do not use the suffix (e.g., `migrate`, `seed`).

**`main.go` responsibilities** (bootstrap only, no business logic):
1. Load configuration (via `internal/config`).
2. Initialize all layers: storage, messaging, app use cases, transport handlers.
3. Wire dependencies (inject implementations into app layer interfaces).
4. Start servers (HTTP, gRPC, etc.).
5. Handle graceful shutdown.

---

### `internal/config/` — Configuration

Contains configuration structs and loading logic (environment variables, config files, etc.). Used by `cmd/` during bootstrap to provide configuration to all layers.

---

### `internal/app/` — Application Layer (Use Cases)

This is the **use-case orchestration layer**. It coordinates domain objects, storage, messaging, and other infrastructure to fulfill application operations.

**Structure rules:**
- One package per domain concept (e.g., `app/order/`, `app/product/`).
- Each file defines its **own struct** with its **own injected dependencies**.
- Files are named by the role they play:
  - `lifecycle.go` → `Lifecycle` struct: create, cancel, reopen, and other state-transition operations.
  - `querier.go` → `Querier` struct: read/query operations for display.
  - `uploader.go` → `Uploader` struct: upload/import operations.
  - Additional files as needed (e.g., `notifier.go`, `scheduler.go`).

**Interface definitions (dependency inversion):**
- The app layer defines interfaces for storage and messaging that infrastructure packages implement.
- Interfaces are defined in the app layer (consumer side), following Go conventions.
- Example: `app/order/lifecycle.go` defines an `OrderStore` interface; `storage/postgres/order_store.go` implements it.

**Validation:**
- Input validation happens in the app layer, at the boundary where the transport layer passes parameters to use cases.

---

### `internal/core/` — Domain Layer

Contains **domain entities, aggregates, value objects, and domain errors**. This is the heart of the business logic.

**Structure rules:**
- Each package represents a **DDD aggregate**.
  - Example: `core/order/` is the Order aggregate containing `order.go` (aggregate root entity) and `item.go` (child entity).
- **Shared value objects** used by multiple aggregates get their own standalone package.
  - Example: `core/quantity/` is a value object used by both Order and Product.
- **Aggregate-specific value objects/enums** may live in sub-packages within the aggregate package.
  - Example: `core/order/status/` contains order status constants.
- **Domain errors** specific to an aggregate live in that aggregate's package.
  - Example: `ErrOrderNotFound` in `core/order/order.go`.
- **Common domain errors** shared across aggregates live in `core/errors/errors.go`.

**Dependency rules:**
- Core MAY import well-known external libraries that help construct the domain (e.g., `google/uuid` for IDs, `shopspring/decimal` for money calculations).
- Core **MUST NOT** import `platform` packages.
- Core **MUST NOT** import any infrastructure packages (storage, transport, messaging).

---

### `internal/platform/` — Cross-Cutting Infrastructure

Contains **cross-cutting infrastructure concerns** used across multiple layers: logging, authentication, time utilities, identifier generation, etc.

- Can be imported by any layer **except `core`**.
- Examples: `logging/` (structured logger), `auth/` (JWT issuance and verification).

---

### `internal/gen/` — Generated Code

Contains **100% auto-generated code** that is never manually edited. Generated code is committed to the repository.

**Organization:** By protocol/source type (not by domain).
- `gen/oapi/` — OpenAPI-generated HTTP server code (e.g., via ogen).
- `gen/proto/` — Protobuf-generated gRPC code.
- `gen/sql/` — SQL-generated code (e.g., via sqlc).
- Additional sub-packages for other generators as needed.

---

### `internal/transport/` — Transport Layer (Inbound Adapters)

Handles **inbound** communication: HTTP requests, gRPC calls, Kafka message consumption.

**Handler responsibilities (thin handlers):**
1. Parse and decode the incoming request/message.
2. Call the appropriate app layer use case.
3. Format and encode the response.
4. **No business logic, no validation** (validation is in the app layer).

**Structure by protocol:**
- `transport/http/` — HTTP handlers.
  - `transport/http/middleware/` — HTTP middleware (auth, CORS, logging, etc.).
- `transport/grpc/` — gRPC handlers.
  - `transport/grpc/interceptors/` — gRPC interceptors.
- `transport/kafka/` — Kafka consumers (message handlers).
  - File naming: `<entity>_handler.go` (e.g., `order_handler.go`).
  - Consumers call the app layer just like HTTP/gRPC handlers do.

---

### `internal/messaging/` — Messaging Layer (Outbound Adapters)

Contains **message producers/publishers** only. Consumers live in `transport/`.

**Structure by technology:**
- `messaging/kafka/` — Kafka producers.
  - File naming: `<entity>_producer.go` (e.g., `product_producer.go`).
  - Implements an interface defined in the app layer.

---

### `internal/storage/` — Storage Layer (Persistence)

Contains **persistence implementations** that satisfy interfaces defined in the app layer.

**Structure by technology:**
- `storage/postgres/` — PostgreSQL implementations.
- `storage/redis/` — Redis implementations.
- `storage/memory/` — In-memory implementations (e.g., LRU caches).

**File naming:** One file per aggregate per technology.
- `order_store.go` — Implements the `OrderStore` interface from `app/order/`, providing persistence for the entire Order aggregate (orders and order items).
- `product_store.go` — Implements the `ProductStore` interface from `app/product/`.

---

## Tests

- **Unit tests** are co-located with the code they test.
  - Example: `app/order/lifecycle_test.go` tests `app/order/lifecycle.go`.
- Follow standard Go testing conventions (`_test.go` suffix, same package or `_test` package).

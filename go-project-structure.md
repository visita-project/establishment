# Go Project Structure

This document defines the standard Go project structure for services. AI agents and developers MUST follow these concepts when implementing, generating, or modifying code. An example file tree is provided at the end to illustrate how all concepts come together.

---

## Architecture

The project follows a layered architecture. Dependencies flow inward toward the domain core. Infrastructure implementations satisfy interfaces defined by the application layer (dependency inversion principle).

All application code lives under `internal/` to prevent external imports. Entry points live under `cmd/`.

### Layers

| Layer | Package | Responsibility |
|-------|---------|---------------|
| Entry Points | `cmd/` | Bootstrap, wiring, server lifecycle |
| Configuration | `internal/config/` | Config structs and loading |
| Application | `internal/app/` | Use-case orchestration, interface definitions |
| Domain | `internal/core/` | Entities, aggregates, value objects, domain errors |
| Transport | `internal/transport/` | Inbound adapters (HTTP, gRPC, Kafka consumers) |
| Infrastructure | `internal/infra/` | Parent for outbound infrastructure adapters |
| — Messaging | `internal/infra/messaging/` | Outbound adapters (message producers) |
| — Storage | `internal/infra/storage/` | Persistence implementations |
| — External API | `internal/infra/extapi/` | Outbound HTTP/gRPC client integrations |
| Platform | `internal/platform/` | Cross-cutting infrastructure (logging, auth, etc.) |
| Generated | `internal/gen/` | Auto-generated code (OpenAPI, protobuf, sqlc, etc.) |

## Naming Conventions

- **No generic suffixes**: Never use `Service`, `Repository`, `Manager`, `Handler` as struct name suffixes. Names must describe what the struct actually does (e.g., `Lifecycle`, `Querier`, `Uploader`).
- **Storage interfaces**: Use `Store` (not `Storer`, not `Repository`). Example: `OrderStore`.
- **File naming**: Files are named by the role they play — `lifecycle.go`, `querier.go`, `uploader.go`, `order_handler.go`, `order_store.go`.

---

## `cmd/` — Entry Points

Each subdirectory produces a compiled binary. Multiple binaries per repository are allowed.

- **Daemon binaries** use the `d` suffix following Unix convention (e.g., `serverd`, `workerd`).
- **Non-daemon binaries** do not use `d` suffix (e.g., `migrate`, `seed`, `cli`).

`main.go` is responsible for **bootstrap only** — no business logic:
1. Load configuration (via `internal/config`).
2. Initialize all layers: storage, messaging, app use cases, transport handlers.
3. Wire dependencies (inject implementations into app layer interfaces).
4. Start servers (HTTP, gRPC, etc.).
5. Handle graceful shutdown.

---

## `internal/config/` — Configuration

Contains configuration structs and loading logic (environment variables, config files, etc.).

---

## `internal/app/` — Application Layer

The **use-case orchestration layer**. Coordinates domain objects, storage, messaging, and other infrastructure to fulfill application operations.

**Package organization:** One package per domain concept (e.g., `app/order/`, `app/product/`).

**File and struct design:**
- Each file defines its **own struct** with its **own injected dependencies**.
- Files are named by the role they play:
  - `lifecycle.go` → `Lifecycle` struct — state-transition operations (create, cancel, reopen).
  - `querier.go` → `Querier` struct — read/query operations for display.
  - `uploader.go` → `Uploader` struct — upload/import operations.
  - Additional files as needed (e.g., `notifier.go`, `scheduler.go`).

**Dependency inversion:**
- The app layer defines interfaces for storage and messaging that infrastructure packages implement.
- Interfaces are defined on the consumer side (in `app/`), following Go conventions.

**Validation:**
- Input validation happens in the app layer, at the boundary where transport passes parameters to use cases.

---

## `internal/core/` — Domain Layer

The heart of the business logic. Contains **domain entities, aggregates, value objects, and domain errors**.

**Package organization:**
- Each package represents a **DDD aggregate**. The aggregate root entity and its child entities live in the same package.
- **Shared value objects** used by multiple aggregates get their own standalone package at the `core/` level.
- **Aggregate-specific value objects or enums** may live in sub-packages within the aggregate package.
- **Domain errors** specific to an aggregate live in that aggregate's package.
- **Common domain errors** shared across aggregates live in `core/errors/`.

**Dependency rules:**
- Core MAY import well-known external libraries that help construct the domain (e.g., `google/uuid` for IDs, `shopspring/decimal` for money).
- Core **MUST NOT** import `platform` packages.
- Core **MUST NOT** import any infrastructure packages (infra, transport, platform).

---

## `internal/platform/` — Cross-Cutting Infrastructure

Contains **cross-cutting infrastructure concerns** used across multiple layers: logging, authentication, time utilities, identifier generation, etc.

Can be imported by any layer **except `core`**.

---

## `internal/infra/` — Infrastructure Adapters

Groups all **outbound infrastructure adapter** packages under a single parent to keep the `internal/` root clean. Contains three sub-packages:

- `infra/messaging/` — message producers/publishers.
- `infra/extapi/` — outbound HTTP and gRPC client integrations.
- `infra/storage/` — persistence implementations.

All three follow the same dependency inversion pattern: they implement interfaces defined in the `app` layer.

---

## `internal/infra/extapi/` — External API Integrations

Contains **outbound HTTP and gRPC client implementations** for integrating with external services.

Organized by protocol: `infra/extapi/http/` for HTTP clients, `infra/extapi/grpc/` for gRPC clients. Files are named after the external service with the `_client.go` suffix (e.g., `payment_client.go`, `inventory_client.go`). Flat files under each protocol — no sub-packages per service.

Each client implements an interface defined in the app layer, following the same dependency inversion pattern as storage and messaging.

---

## `internal/gen/` — Generated Code

Contains **auto-generated code** that MUST NOT be manually edited.

Each generator gets its own sub-package (e.g., `oapi/` for OpenAPI, `proto/` for protobuf, `sqlc/` for sqlc).

---

## `internal/transport/` — Transport Layer (Inbound)

Handles **inbound** communication: HTTP requests, gRPC calls, Kafka message consumption.

**Handler responsibilities (thin handlers):**
1. Parse and decode the incoming request/message.
2. Call the appropriate app layer use case.
3. Format and encode the response.
4. **No business logic, no validation** (validation belongs in the app layer).

**Organization by protocol:**
- Each protocol gets its own sub-package (e.g., `http/`, `grpc/`, `kafka/`).
- HTTP middleware lives under `transport/http/middleware/`.
- gRPC interceptors live under `transport/grpc/interceptors/`.
- Kafka consumers use the `_handler.go` file suffix and call the app layer just like HTTP/gRPC handlers.

---

## `internal/infra/messaging/` — Messaging (Outbound)

Contains **message producers/publishers only**. Consumers live in `transport/`.

Organized by technology (e.g., `kafka/`). Producer files use the `_producer.go` suffix. Each producer implements an interface defined in the app layer.

---

## `internal/infra/storage/` — Storage

Contains **persistence implementations** that satisfy interfaces defined in the app layer.

Organized by technology (e.g., `postgres/`, `redis/`, `memory/`). One file per aggregate per technology, using the `_store.go` suffix. A single store file provides persistence for the entire aggregate (root entity and all child entities).

---

## Tests

- **Unit tests** are co-located with the code they test (e.g., `app/order/lifecycle_test.go` tests `app/order/lifecycle.go`).
- Follow standard Go testing conventions (`_test.go` suffix, same package or `_test` package).

---

## Example File Tree

The following tree illustrates an order service project applying all concepts above:

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
│   │   ├── lifecycle_test.go
│   │   ├── querier.go
│   │   └── querier_test.go
│   └── product/
│       ├── uploader.go
│       ├── uploader_test.go
│       ├── querier.go
│       └── querier_test.go
├── core/
│   ├── errors/
│   │   ├── errors.go
│   │   └── errors_test.go
│   ├── order/
│   │   ├── status/
│   │   │   ├── status.go
│   │   │   └── status_test.go
│   │   ├── order.go
│   │   ├── order_test.go
│   │   ├── item.go
│   │   └── item_test.go
│   ├── product/
│   │   ├── product.go
│   │   └── product_test.go
│   └── quantity/
│       ├── quantity.go
│       └── quantity_test.go
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
├── infra/
│   ├── messaging/
│   │   └── kafka/
│   │       └── product_producer.go
│   ├── extapi/
│   │   ├── http/
│   │   │   └── payment_client.go
│   │   └── grpc/
│   │       └── inventory_client.go
│   └── storage/
│       ├── postgres/
│       │   ├── order_store.go
│       │   └── product_store.go
│       ├── redis/
│       │   └── product.go
│       └── memory/
│           └── product_lru_cache.go
go.mod
go.sum
```

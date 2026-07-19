# buf (gRPC API)

Initialize protobuf linting and Go code generation with buf. Load this reference only when the user selected "gRPC API" in the interview.

## Steps

1. Add the tools to `[tools]` in `mise.toml`, pinning versions from `mise latest <tool>`:
   ```toml
   buf = "<version>"
   protoc-gen-go = "<version>"
   protoc-gen-go-grpc = "<version>"
   ```
   Then run `mise install`.
2. Derive the proto package name `<pkg>` from the repo name (lowercase, strip `-`/`_`/`.`, e.g. `order-service` → `orderservice`) and **confirm it with the user**. `<Pkg>` is the title-cased form (e.g. `Orderservice`); `<module>` is the Go module path from `scripts/git-module-name.sh`.
3. Copy `assets/buf/buf.yaml` → `buf.yaml`.
4. Copy `assets/buf/buf.gen.yaml` → `buf.gen.yaml`.
5. Copy `assets/buf/service.proto` → `api/proto/<pkg>/v1/<pkg>.proto`; replace `<pkg>`, `<Pkg>`, `<module>`.
6. Add the tasks to `mise.toml`:
   ```toml
   [tasks."gen:proto"]
   run = "buf generate"

   [tasks."lint:proto"]
   run = "buf lint"
   ```
7. Gate — run in order, fix and re-run on failure:
   ```bash
   mise run lint:proto
   mise run gen:proto
   mise exec -- go mod tidy
   mise run build
   mise run lint
   ```

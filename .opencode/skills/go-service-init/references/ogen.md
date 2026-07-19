# ogen (HTTP API)

Initialize OpenAPI-first HTTP codegen with ogen. Load this reference only when the user selected "HTTP API" in the interview.

## Steps

1. Add the tool to `[tools]` in `mise.toml`, pinning the version from `mise latest go:github.com/ogen-go/ogen/cmd/ogen`:
   ```toml
   "go:github.com/ogen-go/ogen/cmd/ogen" = "<version>"
   ```
   Then run `mise install`.
2. Copy `assets/ogen/openapi.yaml` → `api/openapi/openapi.yaml`; replace `<service>` with the service/repo name (ask the user if unclear).
3. Copy `assets/ogen/.ogen.yml` → `.ogen.yml`.
4. Add the generation task to `mise.toml`:
   ```toml
   [tasks."gen:oapi"]
   run = "ogen --config .ogen.yml --target gen/oapi --package oapi --clean api/openapi/openapi.yaml"
   ```
5. Gate — run in order, fix and re-run on failure:
   ```bash
   mise run gen:oapi
   mise exec -- go mod tidy
   mise run build
   mise run lint
   ```

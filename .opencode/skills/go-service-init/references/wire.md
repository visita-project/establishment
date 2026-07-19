# Wire (Dependency Injection)

Initialize compile-time dependency injection with the goforj/wire fork. Load this reference only when the user selected "Dependency injection" in the interview.

## Steps

1. Add the tool to `[tools]` in `mise.toml`, pinning the version from `mise latest go:github.com/goforj/wire/cmd/wire`:
   ```toml
   "go:github.com/goforj/wire/cmd/wire" = "<version>"
   ```
   Then run `mise install`.
2. Copy `assets/wire/wire.go` → `cmd/<binary>/wire.go`.
3. Add the task to `mise.toml`:
   ```toml
   [tasks."gen:wire"]
   run = "wire ./cmd/<binary>/..."
   ```
4. Gate — run in order, fix and re-run on failure (`go mod tidy` comes BEFORE `gen:wire`, unlike the codegen flows):
   ```bash
   mise exec -- go mod tidy
   mise run gen:wire
   mise run build
   mise run lint
   ```

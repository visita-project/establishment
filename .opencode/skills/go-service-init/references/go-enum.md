# go-enum (Enums)

Initialize type-safe enum generation with go-enum. Load this reference only when the user selected "Domain enums" in the interview.

go-enum has NO config file. Enums are declared as annotated types (`// ENUM(...)`) in code, each carrying a `//go:generate` directive.

## Steps

1. Add the tool to `[tools]` in `mise.toml`, pinning the version from `mise latest go:github.com/abice/go-enum`:
   ```toml
   "go:github.com/abice/go-enum" = "<version>"
   ```
   Then run `mise install`.
2. Add the task to `mise.toml`:
   ```toml
   [tasks."gen:enum"]
   run = "go generate ./..."
   ```
3. Gate:
   ```bash
   mise run gen:enum   # passes vacuously — no go:generate directives exist yet
   mise run build
   mise run lint
   ```

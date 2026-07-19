# goverter (Struct Converters)

Initialize type-safe struct-to-struct conversion with goverter. Load this reference only when the user selected "Struct converters" in the interview.

goverter has NO config file — conversion is configured via `// goverter:*` comment directives on converter interfaces.

## Steps

1. Add the tool to `[tools]` in `mise.toml`, pinning the version from `mise latest go:github.com/jmattheis/goverter/cmd/goverter`:
   ```toml
   "go:github.com/jmattheis/goverter/cmd/goverter" = "<version>"
   ```
   Then run `mise install`.
2. Add the task to `mise.toml`:
   ```toml
   [tasks."gen:conv"]
   run = "goverter gen ./..."
   ```
3. Gate:
   ```bash
   mise run gen:conv
   mise run build
   mise run lint
   ```

# mockgen (Test Mocks)

Initialize mock generation with uber-go/mock (mockgen). Load this reference only when the user selected "Test mocks" in the interview.

mockgen has NO config file. Mocks are generated via `//go:generate` directives placed in the source files that declare interfaces.

## Steps

1. Add the tool to `[tools]` in `mise.toml`, pinning the version from `mise latest go:go.uber.org/mock/mockgen`:
   ```toml
   "go:go.uber.org/mock/mockgen" = "<version>"
   ```
   Then run `mise install`.
2. Add the task to `mise.toml`:
   ```toml
   [tasks."gen:mocks"]
   run = "go generate ./..."
   ```
3. Gate:
   ```bash
   mise run gen:mocks
   mise run build
   mise run lint
   ```

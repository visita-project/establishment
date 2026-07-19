# Base Scaffold

Always executed. Creates the Go module (name derived from the git remote), the mise toolchain, lint config, and the `cmd/<binary>/` entrypoint. `<binary>` is the binary name from the interview (default `serverd`).

## Steps

1. Extract the module path:
   ```bash
   scripts/git-module-name.sh
   ```
   Prints e.g. `github.com/org/repo`. If the result looks wrong → confirm with the user before continuing.
2. Resolve tool versions and pin the latest:
   ```bash
   mise latest go
   mise latest golangci-lint
   ```
3. Copy `assets/base/mise.toml` → `mise.toml`; replace `<go-version>`, `<lint-version>`, `<binary>`.
4. Install the toolchain: `mise install`
5. Initialize the module with the path from step 1: `mise exec -- go mod init <module-path>`
6. Copy `assets/base/.gitignore` → `.gitignore` (verbatim).
7. Copy `assets/base/.golangci.yaml` → `.golangci.yaml` (verbatim — v2 defaults only, extend later).
8. Copy `assets/base/main.go` → `cmd/<binary>/main.go` (verbatim).
9. **Gate:** `mise run build` must pass. If it fails, fix and re-run before continuing.

## Gotchas

- Pin tool versions with `mise latest <tool>`; when a short name does not resolve, use the fully-qualified backend (e.g. `aqua:golangci/golangci-lint`) in the `[tools]` entry.
- Never commit `mise.local.toml` — it holds local-only env overrides and credentials; the `.gitignore` asset already excludes it.

# PostgreSQL (sqlc + golang-migrate)

Initialize type-safe data access with sqlc and schema migrations with golang-migrate. Load this reference only when the user selected "PostgreSQL storage" in the interview.

## Steps

1. Add the tools to `[tools]` in `mise.toml`, pinning versions from `mise latest <tool>`:
   ```toml
   sqlc = "<version>"
   gomigrate = "<version>"
   ```
   Then run `mise install`.
2. Add `DATABASE_URL` to `mise.local.toml` (gitignored — never committed). `<db>` is the repo name with `-` replaced by `_` (e.g. `order-service` → `order_service`); confirm with the user if unclear:
   ```toml
   [env]
   DATABASE_URL = "pgx://postgres:postgres@localhost:5432/<db>?sslmode=disable"
   ```
3. Copy `assets/postgres/sqlc.yaml` → `sqlc.yaml`.
4. Create `migrations/.gitkeep`, and copy `assets/postgres/query.sql` → `internal/infra/storage/postgres/queries/query.sql`.
5. Add the tasks to `mise.toml`:
   ```toml
   [tasks."gen:sqlc"]
   run = "sqlc generate"

   [tasks."migrate:create"]
   usage = '''
   arg "<name>" help="Migration name"
   '''
   run = "migrate create -seq -ext sql -dir migrations ${usage_name}"

   [tasks."migrate:up"]
   run = "migrate -path migrations -database $DATABASE_URL up"

   [tasks."migrate:down"]
   run = "migrate -path migrations -database $DATABASE_URL down"
   ```
6. Gate — run in order, fix and re-run on failure:
   ```bash
   mise run gen:sqlc
   mise exec -- go mod tidy
   mise run build
   mise run lint
   ```
   `migrate:up` / `migrate:down` require a running database — do NOT run them during init.

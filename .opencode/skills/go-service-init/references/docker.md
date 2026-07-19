# Docker (Dockerfile + docker-compose)

Initialize containerization: a multi-stage Dockerfile for the app binary and a docker-compose file for local development dependencies. Load this reference only when the user selected "Docker" in the interview.

## Steps

1. Copy `assets/docker/Dockerfile` → `Dockerfile`; replace `<go-version>` with the major.minor of the Go version pinned in `mise.toml` (e.g. `1.26.5` → `1.26`) and `<binary>` with the binary name from the interview.
2. Copy `assets/docker/.dockerignore` → `.dockerignore`.
3. Copy `assets/docker/docker-compose.postgres.yml` → `docker-compose.yml` ONLY if at least one backing service was selected in the interview (e.g. PostgreSQL); replace `<db>` so `POSTGRES_DB` matches `DATABASE_URL` from the postgres flow. If no backing service was selected, skip this file entirely — it is added later when one appears. If the user mentions needing other services (Redis, Kafka, ...) and you are unsure, ask.
4. Add the tasks to `mise.toml` (only when `docker-compose.yml` exists):
   ```toml
   [tasks."dev:up"]
   run = "docker-compose up -d"

   [tasks."dev:down"]
   run = "docker-compose down"
   ```
5. Gate:
   ```bash
   mise run build
   mise run lint
   ```
   If a docker daemon is available (`docker version` succeeds), also verify the image builds: `docker build -t <service>:init .`. If no daemon is available, skip the image build and say so in the final report.

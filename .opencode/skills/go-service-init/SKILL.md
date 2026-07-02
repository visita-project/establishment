---
name: go-service-init
description: Initialize a Go service project skeleton so the user can start writing code immediately. Use when the user asks to bootstrap, scaffold, or set up a new Go service project with a minimal structure.
---

Initialize a minimal Go service project skeleton. Execute every step in order and confirm success before moving on. If a step fails or an instruction is ambiguous, stop and ask the user for clarification.

## Steps

1. **Verify Go is installed**
   - Run `go version`.
   - If it errors or returns no output, stop and ask the user to install Go before continuing.

2. **Initialize the Go module**
   - Determine the module path:
     - Run `git remote -v`. If a remote named `origin` exists, use its URL to derive the module path (strip the protocol and trailing `.git`).
     - If there are multiple remotes and none is `origin`, or the directory is not a Git repository, ask the user: "Go module path:" and use their answer.
   - Run `go mod init <module-path>`.

3. **Create the project structure**
   Create the following files and folders in the project root if they do not already exist:
   - File `cmd/serverd/main.go` containing `package main` and an empty `main` function.
   - Folder `internal/` for unexported application code.
   - `mise.local.toml` for local environment variables, using the template at `assets/templates/mise.local.toml`.
   - `mise.toml` for shared tools and tasks, using the template at `assets/templates/mise.toml`.

4. **Optional OpenAPI spec**
   - Ask the user whether to initialize an OpenAPI spec.
   - If yes, create `docs/openapi.yaml` from the template at `assets/templates/openapi.yaml`.
   - If no, skip this step.

## Report

When all selected steps complete successfully, report it and print the working directory tree showing the newly created files and folders.

## Resources

- `assets/templates/mise.local.toml` — local environment file template.
- `assets/templates/mise.toml` — tools and tasks file template.
- `assets/templates/openapi.yaml` — OpenAPI 3.0 spec boilerplate template.
# Local development

The fastest way to work on this repo is the **Dev Container** — a reproducible environment with
everything preinstalled. This is the entry point; it links to the detailed docs.

## Open in a Dev Container (recommended)

Open the repo in its [Dev Container](../.devcontainer/devcontainer.json):

- **VS Code** — "Dev Containers: Reopen in Container" (needs the Dev Containers extension), or
- **CLI** — `make dev` (wraps `devcontainer up`; needs the devcontainer CLI).

You get Node 22, the Playwright Chromium (for the PDF), Docker access, Python + uv, the spec-kit
`specify` CLI, the `gh` + Claude Code CLIs, and editor extensions for the CI linters. It runs as
`root` with host Docker access, and `.claude/settings.json` pre-approves common read-only commands
so agents hit fewer permission prompts.

> Without a Dev Container you can build with just Node + npm (`npm ci`), but you'll also need a
> Chromium for the PDF and Docker for `make lint` / `make build`. The container is the supported path.

## Everyday commands

Everything goes through the `Makefile` — run `make <target>`:

| Task | Command | Notes |
| ---- | ------- | ----- |
| Preview (build + watch + serve) | `npm start` | serves `dist/` on port 8080 |
| One-off build (HTML + PDF) | `make page` | writes to `dist/` |
| Fast lint (inner loop) | `make lint-fast` | native JS + Markdown; approximates CI |
| Full lint (CI parity) | `make lint` | the Super-Linter image; the authoritative gate |
| Dockerized build | `make build` / `make dev-build` | into the shared volume / copied to `dist/` |

Edit CV **content** in `src/metadata/metadata.js`. For the architecture and build pipeline see
[architecture.md](architecture.md); for CI and deployment see [ci-cd.md](ci-cd.md).

## Working on a change

1. **Raise an issue** and branch — see [contributing.md](contributing.md).
2. For a non-trivial feature, go **spec-first** with spec-kit (`/speckit-specify` → `/speckit-plan`
   → `/speckit-tasks` → `/speckit-implement`) — see [spec-driven.md](spec-driven.md).
3. **Self-review** any change over 10 lines with `/code-review` before opening a PR (enforced by a
   Stop hook); validate locally with `make lint-fast` / `make lint`.
4. Open a PR that links its issue (`Closes #<n>`), keep docs in sync in the same PR, and record
   significant decisions as an [ADR](adr/).

See [`AGENTS.md`](../AGENTS.md) for the full set of conventions.

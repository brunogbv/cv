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

**How the image is built (convention):** `.devcontainer/Dockerfile` **bakes the heavy,
workspace-independent tooling into the image** — the Playwright Chromium (+ its OS deps), the
spec-kit `specify` CLI, and the Claude Code CLI — so they persist across container rebuilds and are
cheap to spin up per git worktree. `postCreate` runs only workspace-specific steps (`npm ci`, plus a
Chromium no-op that just re-downloads if the pinned Playwright version changes). When adding Dev
Container tooling, **put workspace-independent installs in the Dockerfile, not `postCreate`.**
`node_modules` and the npm cache live in named volumes — a **per-worktree** `node_modules` volume (so
worktrees stay isolated and the container never clobbers the host's `node_modules`) plus a shared npm
cache — which also makes `npm ci` fast on macOS. Removing a worktree with `make worktree-rm` (or
`make worktree-prune`, which sweeps all merged worktrees) drops its `node_modules` volume too; the
shared npm cache persists across removals (reclaim it with `docker volume rm cv-npm-cache` if it ever
grows large).

**Pinning (reproducibility).** Per constitution Principle V ("pin what determines output"), the Dev
Container inputs are pinned: the `.devcontainer/Dockerfile` base image is pinned by its multi-arch
**index digest** (`…:22-bookworm@sha256:…`, resolving on both amd64/CI and arm64/Apple Silicon), and
the `devcontainer.json` features are pinned to exact versions (e.g. `python:1.8.0` — the *feature*
version, independent of the Python it installs via `"version": "3.12"`) rather than the moving `:1`
major tag. This freezes those inputs — including the features' own patch/security updates — until
someone bumps them, so refresh **deliberately**, not incidentally:

- **Base image** — re-resolve the tag's index digest and update it in the Dockerfile (the exact
  `curl` command is in a comment above the `FROM`).
- **Features** — bump to a newer published version from
  [`devcontainers/features`](https://github.com/devcontainers/features) (e.g.
  `ghcr.io/devcontainers/features/python:<x.y.z>`).

After either bump, rebuild (`devcontainer build --workspace-folder .` or `make dev`) and confirm the
image builds and hadolint stays green (via `make lint`).

Not everything is pinned: the global CLIs baked into the Dockerfile (`uv`, the spec-kit `specify`
CLI, `claude-code`) and the `gh` binary the `github-cli` feature installs still fetch their latest at
build time — only the base image and the feature *packages* are pinned.

> Without a Dev Container you can build with just Node + npm (`npm ci`), but you'll also need a
> Chromium for the PDF and Docker for `make lint` / `make build`. The container is the supported path.

## Everyday commands

Everything goes through the `Makefile` — run `make <target>`:

| Task | Command | Notes |
| ---- | ------- | ----- |
| New branch (isolated worktree) | `make worktree name=<b>` | fetches + branches off `origin/main` into `../cv-<b>` |
| Remove a worktree | `make worktree-rm name=<b>` | removes `../cv-<b>` + its per-worktree `node_modules` volume |
| Prune merged worktrees | `make worktree-prune` | removes every worktree whose PR merged (branch + `node_modules` volume); auto-runs before `make worktree` |
| Preview (build + watch + serve) | `npm start` | serves `dist/` on port 8080 (needs host Node) |
| Build in the container (HTML + PDF) | `make page-container` | **preferred** — builds inside the Dev Container; host stays clean |
| Build on the host (HTML + PDF) | `make page` | needs host Node + Playwright Chromium |
| Fast lint (inner loop) | `make lint-fast` | native JS + Markdown; approximates CI |
| Full lint (CI parity) | `make lint` | the Super-Linter image; the authoritative gate |
| Dockerized build | `make build` / `make dev-build` | into the shared volume / copied to `dist/` |

> **Builds and PDF rendering run in the Dev Container (or CI), not the host.** The PDF is rendered
> with the pinned Playwright Chromium the container/CI provide — `make page-container` runs the build
> inside the container so you never install Node or a browser on your host. `make page` (a host
> build) remains for when you already have the toolchain, but the container is the supported path.

Edit CV **content** in `src/metadata/metadata.js`. For the architecture and build pipeline see
[architecture.md](architecture.md); for CI and deployment see [ci-cd.md](ci-cd.md).

## Working on a change

1. **Raise an issue**, then start the work in an isolated worktree: `make worktree name=<branch>`
   (fetches and branches off `origin/main`, so you never build on a stale base) — see
   [contributing.md](contributing.md).
2. For a non-trivial feature, go **spec-first** with spec-kit (`/speckit-specify` →
   `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`) — see
   [spec-driven.md](spec-driven.md).
3. **Self-review** any change over 10 lines with `/code-review` before opening a PR (enforced by a
   Stop hook); validate locally with `make lint-fast` / `make lint`.
4. Open a PR that links its issue (`Closes #<n>`), keep docs in sync in the same PR, and record
   significant decisions as an [ADR](adr/).

See [`AGENTS.md`](../AGENTS.md) for the full set of conventions.

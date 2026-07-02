# The Curriculum Vitae

[![Lint](https://github.com/brunogbv/cv/actions/workflows/superlinter.yml/badge.svg)](https://github.com/brunogbv/cv/actions/workflows/superlinter.yml)
[![Deploy](https://github.com/brunogbv/cv/actions/workflows/deploy.yml/badge.svg)](https://github.com/brunogbv/cv/actions/workflows/deploy.yml)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/brunogbv/cv)

Hosted at: [https://valerio.dev](https://valerio.dev)

A CV managed as code: a small Node.js static-site generator that renders a single HTML page and a
matching PDF from a structured data file, then deploys them to [Vercel](https://vercel.com) on every
push — with automatic TLS and a consistent HTML + PDF pair.

<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/nodejs.svg" alt="nodejs Logo" width="40" height="40" /> &nbsp; &nbsp;
<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/npm.svg" alt="npm Logo" width="40" height="40" /> &nbsp; &nbsp;
<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/html.svg" alt="html Logo" width="40" height="40" /> &nbsp; &nbsp;
<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/css.svg" alt="css Logo" width="40" height="40" /> &nbsp; &nbsp;
<img src="https://raw.githubusercontent.com/dheereshagrwal/colored-icons/f926a9cacef437021842aa53029d1b73fb03de15/svg/js.svg" alt="js Logo" width="40" height="40" />

## What does this project do?

- Manages a CV as a static web app (HTML + CSS) plus a matching PDF, both generated at build time.
- Builds in GitHub Actions and deploys the prebuilt output to Vercel on every push — **production**
  from `main`, a **preview** per pull request — with automatic, auto-renewing TLS.

## Documentation

Developer documentation lives in [`docs/`](docs/):

- [Local development](docs/local-development.md) — set up the Dev Container, everyday commands, and the change workflow (start here).
- [Architecture](docs/architecture.md) — code structure, the build pipeline, the content data model, and how the site is served.
- [CI/CD](docs/ci-cd.md) — the GitHub Actions workflows (Lint, Dev Container prebuild, Vercel Deploy) and the Vercel deploy model.
- [`AGENTS.md`](AGENTS.md) — conventions for working in this repo (build via the Makefile, Dev Container, spec-driven development).

## Getting started

The quickest setup is the [Dev Container](.devcontainer/devcontainer.json): open the repo in it (VS Code "Reopen in Container", `make dev`, or `devcontainer up`) for a ready-made environment — Node 22, the Playwright Chromium used for the PDF build, Docker access for `make lint` / `make dev-build`, Python + uv, and the spec-kit `specify` CLI — with no local Node or Chromium install.

> The container runs as `root` and mounts the host Docker socket (both needed to run the Docker-based `make` targets from inside it), so treat it as having full host Docker access.

Without the Dev Container you can build with just **Node + npm** (`npm ci`); `make lint` and
`make dev-build` additionally need **Docker**.

## Usage

Everything goes through the `Makefile`. The common targets:

### Develop & build

- **`make dev`** — open the project in its Dev Container.
- **`npm start`** — build, watch, and serve `dist/` on a local live-server (needs local Node).
- **`make page`** — build the HTML + PDF with your local toolchain (needs Node + a Chromium).
- **`make page-container`** — build inside the Dev Container; the host stays clean (**preferred**).
- **`make dev-build`** — dockerized build, output copied into `./dist` (no local Node needed).

### Lint

- **`make lint`** — full Super-Linter, matching CI.
- **`make lint-fast`** — quick JavaScript + Markdown lint for the inner loop.
- **`make lint-actions`** — `actionlint` on the GitHub Actions workflows.

### Deploy

Deployment is **automatic** — GitHub Actions builds and deploys to Vercel on every push (production
from `main`, a preview per PR). `make deploy` is the underlying command the workflow runs (it wraps
`vercel build` + `vercel deploy --prebuilt`); you don't normally run it by hand. See
[docs/ci-cd.md](docs/ci-cd.md).

## Editing content

Edit the CV content in [`src/metadata/metadata.js`](src/metadata/metadata.js). The page template is
[`src/templates/index.html`](src/templates/index.html) (Handlebars + Bootstrap 5 markup) and styling
is in [`src/assets/styles.css`](src/assets/styles.css). For the build pipeline and data model, see
[docs/architecture.md](docs/architecture.md).

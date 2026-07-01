# Documentation

Developer documentation for the CV project — a small Node.js static-site generator that renders
a single-page CV to HTML + PDF and serves it at [valerio.dev](https://valerio.dev).

For day-to-day commands (build, lint, deploy), see the root [`README.md`](../README.md). For an
agent-oriented quick reference, see [`AGENTS.md`](../AGENTS.md).

## Contents

- **[Architecture](architecture.md)** — code structure, the build pipeline, the content data
  model, and how the site is served.
- **[CI/CD](ci-cd.md)** — GitHub Actions workflows and the (manual) Docker-based deployment.
- **[Contributing & Issue Tracking](contributing.md)** — how work is tracked in GitHub (issues,
  milestones, projects) and how to raise a well-formed issue.
- **[Architecture Decision Records](adr/)** — significant technical decisions and their rationale.
- **[Spec-driven development](spec-driven.md)** — the spec-kit `/speckit-*` workflow for non-trivial features.

## At a glance

| Aspect        | Summary                                                                 |
| ------------- | ----------------------------------------------------------------------- |
| Language      | JavaScript (Node.js)                                                    |
| Templating    | Handlebars                                                              |
| PDF           | Playwright (headless Chromium)                                          |
| Content       | A single data file: `src/metadata/metadata.js`                          |
| Output        | `dist/` (generated, gitignored)                                         |
| Serving       | nginx (Docker Compose) with Let's Encrypt TLS via certbot               |
| CI            | GitHub Actions — Super-Linter (lint-only, no tests)                     |
| CD            | Manual (`make` targets on the host)                                     |

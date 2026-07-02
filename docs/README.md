# Documentation

Developer documentation for the CV project — a small Node.js static-site generator that renders
a single-page CV to HTML + PDF and serves it at [valerio.dev](https://valerio.dev).

For day-to-day commands (build, lint, deploy), see the root [`README.md`](../README.md). For an
agent-oriented quick reference, see [`AGENTS.md`](../AGENTS.md).

## Contents

- **[Local development](local-development.md)** — set up the Dev Container, everyday commands, and
  the change workflow (the entry point for working on this repo).
- **[Architecture](architecture.md)** — code structure, the build pipeline, the content data
  model, and how the site is served.
- **[CI/CD](ci-cd.md)** — the GitHub Actions workflows (Lint, Dev Container prebuild, Vercel Deploy) and the Vercel deploy model.
- **[Contributing & Issue Tracking](contributing.md)** — how work is tracked in GitHub (issues,
  milestones, labels; projects optional) and how to raise a well-formed issue.
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
| Serving       | Vercel (static hosting, automatic TLS)                                  |
| CI            | GitHub Actions — lint, Dev Container prebuild, Vercel deploy            |
| CD            | GitHub Actions -> Vercel (push to `main` = prod, PR = preview)          |

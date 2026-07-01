# 0001 — Modernize the build runtime: Node 22 + Playwright

- **Status:** Accepted — implemented in PR #23 (issue #17)
- **Date:** 2026-07-01

## Context

The build (`src/build.js`) renders the CV to a single HTML page (Handlebars) and then to a PDF via
a headless browser. Originally that used **Puppeteer** on an **EOL Node 14** base image, with a
hard-pinned `google-chrome-stable=127…` and fixed font/lib versions installed through the Google
apt repo in the `Dockerfile`.

Problems and forces:

- **Node 14 is end-of-life** — no security updates, and it blocks adopting a modern devcontainer
  (the goal of the "Local development with devcontainers" milestone).
- The hard-pinned apt packages **rot**: Debian eventually drops exact versions from its mirrors, so
  the build breaks over time.
- **Consistent, reproducible builds are non-negotiable** — the browser version must be pinned, not
  floating.
- Builds should run **inside the devcontainer on the maintainer's Apple Silicon (arm64) Mac**,
  natively (no emulation) for a fast loop, while CI and prod run amd64.

The decisive constraint surfaced during implementation: **Puppeteer's browser (Chrome for Testing)
has no `linux-arm64` build — only `linux-amd64`.** So a pinned-Puppeteer image is amd64-only; on
arm64 it must emulate, and emulated Chrome fails to launch (verified: a 5-minute launch timeout
under Rosetta). Meanwhile the distro's Chromium is arm64-native but **unpinned** (fails the
consistency bar), and pinning its apt version rots.

## Decision

Modernize the build runtime:

- **Node 22 LTS** (`node:22-bookworm-slim`), declared via `engines.node >= 22.12.0`.
- **Playwright** (exact-pinned `1.61.1`) replaces Puppeteer for HTML → PDF. Playwright ships a
  **version-pinned Chromium that includes a `linux-arm64` build**, so the browser is:
  - **pinned** to the Playwright version via `package-lock.json` (reproducible), and
  - **arch-native** on both arm64 (devcontainer) and amd64 (CI/prod) — no emulation.
- The `Dockerfile` installs the browser and its OS dependencies with
  `playwright install --with-deps chromium` — no hand-maintained apt lib list, no `--platform` pin,
  no Google apt-repo/`apt-key` dance.
- `src/utils/pdf.js` uses `chromium.launch()` / `page.pdf()` with the launch args
  `--no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage` and `waitUntil: 'networkidle'`.

## Alternatives considered

- **Bump Puppeteer, keep it (amd64-only, emulated locally).** Rejected — can't build natively in an
  arm64 devcontainer; emulated Chrome would not launch.
- **Puppeteer + distro Chromium, unpinned.** Rejected — the browser version floats, failing the
  consistency requirement, and risks Puppeteer↔Chromium version skew.
- **Puppeteer + distro Chromium pinned via a Debian snapshot mirror.** Rejected — snapshot infra is
  slow/flaky in CI and still leaves a Puppeteer↔Chromium version mismatch.
- **Non-browser converters (wkhtmltopdf, WeasyPrint).** Rejected — their CSS engines don't match
  Chromium; the CV uses Bootstrap 5 (flexbox/grid) + custom print CSS, so PDF fidelity would
  regress.

## Consequences

**Positive**

- Reproducible builds — the browser is pinned to the Playwright version through the lockfile.
- Native on both arm64 (devcontainer, fast local loop) and amd64 (CI/prod) — no emulation.
- Simpler `Dockerfile` — drops the Google apt repo, `apt-key`, and the brittle hard-pinned
  package versions.
- Supported, secure Node runtime.

**Negative / trade-offs**

- A dependency swap (Puppeteer → Playwright) inside a task nominally about "modernizing Puppeteer".
- Playwright's install is heavier (downloads a browser at build time).
- The render still depends on **remote CDN fonts** (Google Fonts, Bootstrap, Font Awesome) at build
  time — tracked separately in issue #24.

**Verified:** a native arm64 `docker build` + `make page` produces a valid PDF (`%PDF-1.4`).

## References

- PR #23 (implementation), issue #17 (task), issue #24 (follow-up: self-host fonts for offline
  builds)

# Research: Digital CV redesign

Phase 0 findings. Two parallel research passes: (A) deterministic CI-gated visual-regression with
Playwright; (B) rich-screen / simple-PDF from one source + accessible animation. Decisions below feed
`plan.md`, `data-model.md`, `contracts/`, and `quickstart.md`.

## Decision 1 — Visual-regression tooling: `@playwright/test` `toHaveScreenshot()`

- **Decision**: Add **`@playwright/test` pinned to `1.61.1`** (exact, devDependency — same version as the
  existing `playwright` runtime dep) and use its built-in `toHaveScreenshot()` for snapshot testing.
  The existing `src/utils/pdf.js` keeps importing `playwright` unchanged; the two coexist and share
  the one version-pinned Chromium (no duplicate download) **because the versions match**.
- **Rationale**: First-party, no external service, baselines live in-repo — fits the no-backend /
  minimal-pinned-deps constraints. Reuses the browser we already pin.
- **Alternatives**: Percy/Chromatic (external SaaS + secret + cost → rejected); jest-image-snapshot
  (adds a second runner → rejected); BackstopJS (heavier wrapper + own config → rejected).

## Decision 2 — Snapshot determinism (the flakiness risk of the chosen method)

- **Decision**: Generate, update, and compare baselines **only in one consistent Linux environment**
  (the Dev Container / CI `ubuntu-latest`) — never commit host/macOS baselines. Use a
  **platform-neutral `snapshotPathTemplate`** (no `-darwin`/`-linux` suffix) so a stray host run
  can't create a divergent baseline. Set tolerance `maxDiffPixelRatio: 0.01`, keep `threshold: 0.2`,
  `animations: 'disabled'`, `scale: 'css'`, `caret: 'hide'` (last four are defaults, set explicitly).
  Wait on `document.fonts.ready` (Playwright auto-waits for fonts). Baselines refresh only via a
  reviewed `make visual-update` run in the Dev Container.
- **Rationale**: Cross-OS font rasterization (CoreText vs FreeType) is the #1 visual-test flake; a
  single Linux baseline source + the already-**vendored fonts (no CDN)** make rendering deterministic.
  A small ratio tolerance absorbs antialiasing noise without hiding real regressions.
- **Alternatives**: per-platform baselines (doubles maintenance, devs still can't reproduce CI →
  rejected); zero tolerance (flaky on AA noise → rejected); the official `mcr.microsoft.com/playwright`
  image (more infra vs. reusing the existing Dev Container → deferred, not needed).
- **Baseline cadence (tests-first → redesign — important)**: the P1 gate captures baselines from the
  **current, pre-redesign** page, locking today's look. The redesign (P2/P3) then *intentionally*
  changes appearance, so those PRs will (correctly) fail the snapshot check until the author runs
  **`make visual-update`** and commits the new baselines — which are **reviewed in the PR** (image
  diff). So the gate does **not** block the redesign; it makes **every** visual change explicit and
  reviewed, and catches only *unintended* diffs. Each redesign PR = code change + a reviewed baseline
  update.

## Decision 3 — Breakpoints

- **Decision**: One representative width per Bootstrap 5 tier — **375 / 576 / 768 / 992 / 1200 /
  1440** — captured `fullPage`. Six baselines.
- **Rationale**: Covers every real device class the layout targets (Bootstrap xs/sm/md/lg/xl/xxl)
  without excess surface.
- **Alternatives**: 3 widths (misses xxl/edge tiers → the user chose the full set); every pixel
  boundary (excessive → rejected).

## Decision 4 — PDF-render assertion (same gate)

- **Decision**: The Playwright suite also verifies the build's PDF: **exists, non-empty (> ~1 KB),
  and begins with the `%PDF-` magic header** — zero new dependencies. Content-level assertions
  (searching for the name/section headings) would need a parser (`pdf-parse`); **deferred** as an
  optional later add to keep deps minimal.
- **Rationale**: Catches the realistic failure (missing/empty/corrupt PDF) with no new dep, honoring
  Principle V. The header+size check is a strong, cheap signal.
- **Alternatives**: `pdf-parse` content assertions (one more dep → deferred); no PDF check (leaves the
  PDF unguarded, and "PDF still renders" is an explicit spec goal → rejected).

## Decision 5 — Rich screen + simple PDF from ONE source (screen/print CSS split)

- **Decision**: Keep the **single Handlebars template + one CSS file**; extend the existing
  `screen`/`print` split. `page.pdf()` renders **`print` media by default** (Playwright docs,
  confirmed) and `src/utils/pdf.js` never calls `emulateMedia` — so the rich screen chrome lives in
  the default/`@media screen` cascade and `@media print` strips it to today's linear document.
  **`pdf.js` is NOT touched.** Screen-only chrome (sticky nav, cards, animation) goes in the existing
  `.screen` bucket; `@media print` flattens cards (no border/shadow/background/radius), hides the nav,
  and disables animation.
- **Rationale**: One source of truth; the PDF stays simple *by construction* (it already depends on
  default print media). No second template, no `pdf.js` change → PDF generation is not complicated.
- **Alternatives**: a separate print template / separate PDF build (two sources to keep in sync →
  rejected); emulating screen media for the PDF (would pull screen chrome into the PDF → rejected).
- **Pitfalls**: `position: sticky/fixed` repeats on every printed page → keep nav screen-only /
  `static` in print; backgrounds don't print by default (fine — don't rely on them in print); use
  `break-inside: avoid` on experience entries so one isn't split across PDF pages; note the effective
  PDF margin comes from `page.pdf({margin})`, not the `@page` CSS margin — keep them consistent.

## Decision 6 — Animation: CSS + tiny IntersectionObserver, fail-safe

- **Decision**: Scroll-reveal via CSS transitions on **`transform`/`opacity` only** + a small
  one-shot **IntersectionObserver** (no library). Gate the hidden state behind a JS-set `.js`
  root class **and** `@media (prefers-reduced-motion: no-preference)` so the **default (no-JS or
  reduced-motion) is fully visible**; `@media print` forces visible + no motion.
- **Rationale**: Dependency-free, no layout shift (compositor-only props → CLS ≈ 0), accessible
  (reduced-motion honored), and **degrades gracefully** — content is never left `opacity:0` if JS
  fails. Sticky nav uses `position: sticky` + anchor links + `scroll-behavior: smooth` (gated by
  reduced-motion) + `scroll-margin-top`; the mobile menu is a `<details>`/`<summary>` disclosure
  (zero JS, keyboard-accessible).
- **Alternatives**: animation libraries (AOS/GSAP → unnecessary deps, rejected); base `opacity:0`
  without the `.js` gate (blank content on JS failure → rejected footgun); `:target` CSS menu
  (fights the anchor-scroll hash → rejected in favor of `<details>`).

## Decision 7 — Making animation deterministic for snapshots

- **Decision**: For visual tests, force the final rendered state via a test-only **`stylePath`
  snapshot stylesheet** (`.reveal { opacity:1 !important; transform:none !important }`) **and**
  Playwright `reducedMotion: 'reduce'`; rely on the built-in `animations: 'disabled'` for transitions.
  Load the page as `file://dist/index.html` (same as `pdf.js`) — no server.
- **Rationale**: Playwright disables CSS animations for screenshots but does **not** run the
  IntersectionObserver, so below-the-fold reveals could stay hidden and snapshot nondeterministically.
  Forcing the end state (via test-only CSS / reduced-motion) makes captures deterministic without
  touching production CSS. `file://` matches how the PDF is already rendered — zero extra moving parts.
- **Alternatives**: scroll the page to trigger the observer before capture (timing-fragile →
  rejected); a local web server (more moving parts → deferred unless `file://` diverges).

## Decision 8 — CI wiring

- **Decision**: New workflow `.github/workflows/visual.yml` (name e.g. `Visual`), `ubuntu-latest`:
  checkout → Node 22 + `npm ci` → cache `~/.cache/ms-playwright` (keyed on the Playwright version, per
  `deploy.yml`) → `npx playwright install --with-deps chromium` → `make page` → `npx playwright test`
  (compares committed baselines; **fails on a missing baseline** — CI never passes `--update-snapshots`)
  → upload the Playwright HTML report + diff images as an artifact on failure. Make it a **required PR
  check**. Local parity via **`make visual`** (build + test in the Dev Container) and **`make
  visual-update`** (reviewed baseline refresh).
- **Rationale**: Mirrors the existing `deploy.yml` build+cache pattern; `ubuntu-latest` matches the
  Dev Container's Debian FreeType so baselines match. Principle I: the commands live in the Makefile.
- **Alternatives**: fold into `deploy.yml` (mixes concerns; the deploy job shouldn't gate on pixels →
  separate workflow); no CI (defeats the whole "can't silently break it" goal → rejected).

## Cross-cutting note — Constitution Principle IV

Principle IV currently states *"There is no test suite… Linting is the only automated CI gate."* This
feature deliberately **introduces a test suite and a second required CI gate**, so Principle IV must be
**amended** (a harness evolution under Principle VI). Tracked as a Constitution Check finding in
`plan.md` and as a task; the amendment is a version-bumped constitution + AGENTS.md update.

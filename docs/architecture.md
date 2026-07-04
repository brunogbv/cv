# Architecture

The project is a static-site generator with one job: turn a structured CV data file into a
single HTML page and a matching PDF, then serve those static files from Vercel's edge. There is no
backend, database, or client-side framework — the page is plain HTML/CSS produced at build time.

## Directory layout

```text
.
├── src/
│   ├── build.js                  # Build entrypoint: data + template → dist/
│   ├── metadata/
│   │   └── metadata.js           # CV content — the data model (see below)
│   ├── templates/
│   │   └── index.html            # Handlebars page template (Bootstrap 5 markup)
│   ├── assets/                   # Copied verbatim into dist/: styles.css, reveal.js, photo.jpg,
│   │                             #   favicons, url-qr-code.svg
│   └── utils/
│       ├── pdf.js                # Playwright HTML → PDF renderer
│       └── helpers/
│           └── markdown.js       # Handlebars {{markdown}} helper
├── tests/                        # Playwright visual-regression + PDF gate (see ci-cd.md)
│   ├── visual.spec.js            #   fullPage snapshots at the 6 breakpoints
│   ├── pdf.spec.js               #   asserts a valid PDF was built
│   ├── snapshot.css              #   test-only styles for deterministic capture
│   └── __screenshots__/          #   committed baseline PNGs
├── playwright.config.js          # Test runner config (breakpoints, snapshot tolerance)
├── config/
│   └── lint/super-linter.env     # Super-Linter configuration (see ci-cd.md)
├── vercel.json                   # Vercel serving config: prebuilt output + cache/security headers
├── Dockerfile                    # Builder image (node:22 + Playwright Chromium) for `make dev-build`
├── Makefile                      # Dev, build, lint, visual, and Vercel deploy commands
├── package.json                  # npm scripts + dependencies
└── .github/workflows/            # CI: Lint, Visual, Dev Container prebuild, Vercel Deploy
    ├── superlinter.yml
    ├── visual.yml
    ├── devcontainer.yml
    └── deploy.yml
```

`dist/` is the build output and is gitignored — never edit it by hand.

## Build pipeline

The whole build is `src/build.js`, run via `node src/build.js` (wrapped by `npm run build` and
`make page`). In order, it:

1. **Empties `dist/`** — `fs.emptyDirSync(outputDir)` (`outputDir` = `<repo>/dist`).
2. **Copies assets** — `src/assets/` → `dist/` verbatim (styles, `reveal.js`, photo, favicons, QR
   code), and vendors Bootstrap / Font Awesome / Roboto (CSS + fonts) from pinned `node_modules` into
   `dist/vendor/`, so the page and PDF need no CDN at build or render time (#24).
3. **Registers the `markdown` helper** so templates can render Markdown content fields to HTML.
4. **Compiles the template** — reads `src/templates/index.html`, compiles it with Handlebars, and
   renders it with the data from `src/metadata/metadata.js` plus three injected values:
   - `baseUrl` — `https://valerio.dev`
   - `pdfFileName` — slugified `"<name>.<title>.pdf"` (via `speakingurl`)
   - `updated` — today's date, formatted with `dayjs` (`MMMM D, YYYY`)
5. **Writes `dist/index.html`**.
6. **Generates the PDF** — `src/utils/pdf.js` launches headless Chromium (Playwright), loads the
   freshly written `dist/index.html` as a `file://` URL (waiting for `load` + `document.fonts.ready`,
   not network idle — the page has no runtime network dependency), and prints an **A4** PDF with
   **2.54 cm** margins to `dist/<pdfFileName>`.

```text
metadata.js ─┐
             ├─▶ Handlebars ─▶ dist/index.html ─▶ Playwright ─▶ dist/<name>.<title>.pdf
index.html ──┘                      ▲
                                src/assets/ (copied into dist/)
```

Because the PDF is rendered from the same HTML, the two versions stay consistent in **content** by
construction, while their **presentation is decoupled via CSS media** (one template, one stylesheet —
no separate print template). To keep that decoupling watertight, `pdf.js` calls
`page.emulateMedia({ media: 'print' })` **before** navigating, so screen-only rules (`@media not print`)
and screen-only assets (e.g. `media="screen"` webfonts) are never applied or even fetched for the PDF —
it renders exactly the print document. On screen the CV is a rich,
card/section-based layout with a sticky section nav and a subtle scroll-reveal; `@media print` flattens
the cards back to a clean linear document, hides the nav, and disables the animation, so the PDF is
unchanged by the redesign. The `screen` / `print` classes also swap the cross-links — the on-screen
page shows a "Download PDF" link, the print/PDF version a QR code back to the site
(`src/templates/index.html`, `src/assets/styles.css`).

## Content data model

All CV content lives in `src/metadata/metadata.js`, which exports a single object. This is the
**only** file you edit to update CV content. Top-level keys:

| Key            | Type     | Notes                                                              |
| -------------- | -------- | ------------------------------------------------------------------ |
| `name`         | string   | Used in the title, header, and PDF filename slug.                  |
| `title`        | string   | Role/headline; also part of the PDF filename slug.                 |
| `facts`        | array    | Contact/location items, each `{ icon, value }` (raw HTML strings). |
| `about_me`     | string   | Markdown — rendered via the `{{markdown}}` helper.                 |
| `skills`       | array    | Tuples `[label, percent]`; `percent` drives the skill-bar width.   |
| `positions`    | array    | Professional experience (see entry shape below).                   |
| `experience`   | array    | Additional experience (same entry shape).                          |
| `competitions` | array    | Robotics competitions (same shape, without `skills`).              |

Experience-style entries (`positions`, `experience`, `competitions`) have:

- `title` — string
- `period` — string (e.g. `"November 2023 – Present"`)
- `contents` — Markdown string, rendered with `{{markdown}}`
- `skills` — array of strings, rendered as badges (omitted for `competitions`)

`icon` and `value` in `facts` are interpolated as raw HTML (`{{{ }}}`), so they can contain
Font Awesome `<i>` tags and `<a>` links.

## Template & styling

- `src/templates/index.html` is a Handlebars template producing a Bootstrap 5 single-page layout.
  Bootstrap 5.2, Font Awesome 6.1, and Roboto are **vendored** into `dist/vendor/` at build time
  (copied from pinned `node_modules`) and referenced locally — no CDN at runtime (#24).
- Sections rendered: header (photo + name + facts + PDF/QR), then `<main>` with About me, Skills
  (bar chart), Professional Experience, Additional Experience, Robotics Competitions — each a
  `<section id>` (nav anchor). On screen, About and the three experience sections present their content
  as Bootstrap **cards**, while Skills keeps its bare bar-chart grid (un-carded, so its PDF output is
  byte-identical). Lists use Handlebars
  `{{#each}}` over the arrays above; a screen-only sticky **section nav** (a `<details>` menu below
  Bootstrap `md`, an inline list at `md+`) links to the section ids, with its link list defined once as
  a Handlebars inline partial.
- **`<base target="_blank">` gotcha.** The page sets `<base target="_blank">` so external links open
  in a new tab — but that default also applies to in-page anchors (`href="#…"`), which would then open
  a new tab and reload the whole page. Every in-page anchor (the section-nav links, and any future
  card/close/back anchors) must therefore set `target="_self"` to opt back out. See
  [interaction-gotchas.md](interaction-gotchas.md#in-page-anchors).
- `src/assets/styles.css` holds project-specific styling on top of Bootstrap: the `screen` / `print`
  visibility rules, the skill-bar styling, the card/section/nav layout, and the scroll-reveal. The
  screen/print split is media-driven — `@media print` flattens the cards, hides the nav, and disables
  motion so the PDF stays linear (Skills keeps its original grid markup, un-carded, so its print output
  is byte-identical). See the [rendering contract](../specs/002-digital-cv-redesign/contracts/rendering-contract.md).
- `src/assets/reveal.js` is a small progressive-enhancement script (loaded from `<head>`): it sets a
  `.js` root class, then a one-shot `IntersectionObserver` reveals `.reveal` sections as they scroll
  in. It **fails visible** — with no JS, no `IntersectionObserver`, or any error, all content stays
  shown — and the reveal is disabled for reduced-motion users and in print.
- Note: this template/repo originates from the [`sneas/cv-template`](https://github.com/sneas/cv-template)
  project.

## Tests

The one automated test suite is a **visual-regression + PDF-render gate** (Playwright), not a
unit/integration suite — it protects how the site renders across breakpoints and that the PDF still
builds. It lives in `tests/` (`visual.spec.js`, `pdf.spec.js`, `snapshot.css`, committed baselines in
`__screenshots__/`) with `playwright.config.js` at the root, runs via `make visual` / `make
visual-update`, and is a required PR check. See [ci-cd.md](ci-cd.md#visual--pdf-gate) for how it runs
and how baselines are updated.

## Runtime & dependencies

- Local builds use your system Node.js. The **Docker** builder image is based on
  `node:22-bookworm-slim` and runs `playwright install --with-deps chromium`, which installs the
  Chromium build pinned to the Playwright version (in `package-lock.json`) plus its OS
  dependencies. This works natively on both amd64 and arm64, so the build is reproducible without
  emulation (`Dockerfile`).
- Key npm dependencies (`package.json`): `handlebars` (templating), `playwright` (headless
  Chromium → PDF),
  `fs-extra` (file ops), `dayjs` (dates), `speakingurl` (slugs), `markdown` (Markdown→HTML),
  plus dev tooling: `live-server` + `chokidar-cli`/`watch` (dev server) and `stylelint`.

For how the built site is served and deployed, see [ci-cd.md](ci-cd.md).

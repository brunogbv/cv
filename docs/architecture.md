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
│   ├── assets/                   # Copied verbatim into dist/: styles.css, reveal.js, deck.js,
│   │                             #   overlay.js, photo.jpg, favicons, url-qr-code.svg
│   └── utils/
│       ├── pdf.js                # Playwright HTML → PDF renderer
│       └── helpers/
│           └── markdown.js       # Handlebars {{markdown}} helper
├── tests/                        # Playwright visual-regression + PDF gate (see ci-cd.md)
│   ├── visual.spec.js            #   fullPage snapshots at the 6 breakpoints
│   ├── pdf.spec.js               #   asserts a valid PDF was built
│   ├── pdf-visual.spec.js        #   per-page pixel diff of the PDF against baselines
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
   code), and vendors Bootstrap / Font Awesome / Roboto plus the screen-only editorial webfonts
   **Fraunces** (display) and **Spline Sans** (body) (CSS + fonts) from pinned `node_modules` into
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
it renders exactly the print document. On screen the CV is a **full-viewport scroll-snap deck**
(feature 003) — card rails, detail overlays, and a Through-Line signature (see *Template & styling*);
`@media print` flattens all of it to a clean linear document — stacked entries, no deck / rails /
overlays / nav — so the PDF is unchanged by the redesign. The `screen` / `print` classes also swap the cross-links — the on-screen
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
| `skills`       | array    | Categories `[{ category, kind, items }]`; `items` are skill-name strings (no grading). Screen: category-card rails; print: labelled lists. |
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
  Bootstrap, Font Awesome, and Roboto are **vendored** into `dist/vendor/` at build time; feature 003
  added the vendored editorial webfonts **Fraunces** (display serif) and **Spline Sans** (body),
  applied **screen-only** (`media="screen"`) so the PDF keeps Roboto — no CDN at runtime (#24).
- **Sections.** Header (photo + name + facts + PDF/QR), then `<main>` with About me, Skills,
  Professional Experience, Additional Experience, Robotics Competitions — each a `<section id>` (nav
  anchor). A screen-only sticky **section nav** links to the section ids (a `<details>` menu below
  Bootstrap `md`, an inline list at `md+`), its link list defined once as a Handlebars inline partial.
- **The screen "deck" (feature 003).** On screen the page is a **full-viewport scroll-snap deck**: the
  hero and each section fill the viewport and snap into place via native CSS `scroll-snap-type: y
  mandatory` on `<html>` (no scroll-jacking JS). Skills **and** the three content-dense sections render
  as horizontal **card rails** (`.cv-rail` of `.cv-summary` cards); activating a card opens the full
  entry in a full-screen **detail overlay** — a CSS `:target` overlay (`#id` deep-linked, open/close
  works with no JS). A fixed left-gutter **"Through-Line"** progress signature fills as you snap through
  the deck, and a pure-CSS **swipe affordance** (right-edge fade + `›` chevron on `.cv-rail-wrap`) hints
  the rails scroll. Skills are grouped into labelled category cards (Hard/Soft skills, Languages); the
  overlay lists every skill in the category. See the
  [interaction contract](../specs/003-interactive-card-rails/contracts/interaction-contract.md).
- **`<base target="_blank">` gotcha.** The page sets `<base target="_blank">` so external links open
  in a new tab — but that default also applies to in-page anchors (`href="#…"`), which would then open
  a new tab and reload the whole page. Every in-page anchor (the section-nav links, the rail cards, and
  the overlay close/backdrop links) must therefore set `target="_self"` to opt back out. See
  [interaction-gotchas.md](interaction-gotchas.md#in-page-anchors).
- **Styling & screen/print split.** `src/assets/styles.css` holds the project styling on top of
  Bootstrap: the editorial palette + Fraunces/Spline type, the `screen` / `print` visibility rules, the
  deck / rail / overlay / Through-Line layout, and the scroll-reveal. The split is media-driven —
  `@media print` drops the deck's `100vh`/snap, flattens rails and overlays back to the original stacked
  entries, renders Skills as labelled linear lists, and hides the nav / Through-Line / swipe affordance,
  so the PDF stays byte-stable. `pdf.js` additionally emulates print media before navigating (see
  *Build pipeline*).
- **Progressive-enhancement scripts** (loaded from `<head>`, all fail-safe — with no JS, all content
  stays reachable):
  - `reveal.js` — sets a `.js` root class, then one-shot `IntersectionObserver`-reveals `.reveal`
    sections; disabled under reduced-motion / no-JS / print.
  - `deck.js` — one-section-per-keypress keyboard navigation over the snap deck, and drives the
    Through-Line's active/progress state; never intercepts wheel/touch (native snap owns those).
  - `overlay.js` — adds dialog semantics to the `:target` detail overlays (focus move-in, Tab-trap,
    Escape-to-close, focus-return); the `:target` open/close works without it.
- Note: this template/repo originates from the [`sneas/cv-template`](https://github.com/sneas/cv-template)
  project.

## Tests

The one automated test suite is a **visual-regression + PDF-render gate** (Playwright), not a
unit/integration suite — it protects how the site renders across breakpoints and that the PDF still
builds. It lives in `tests/` (`visual.spec.js` — fullPage breakpoint snapshots; `pdf.spec.js` — a
valid-PDF check; `pdf-visual.spec.js` — a per-page pixel diff of the PDF; `snapshot.css`; committed
baselines in `__screenshots__/`) with `playwright.config.js` at the root, runs via `make visual` / `make
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

# Architecture

The project is a static-site generator with one job: turn a structured CV data file into a
single HTML page and a matching PDF, then serve those static files behind nginx. There is no
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
│   ├── assets/                   # Copied verbatim into dist/: styles.css, photo.jpg,
│   │                             #   favicons, url-qr-code.svg
│   └── utils/
│       ├── pdf.js                # Puppeteer HTML → PDF renderer
│       └── helpers/
│           └── markdown.js       # Handlebars {{markdown}} helper
├── config/
│   ├── lint/super-linter.env     # Super-Linter configuration (see ci-cd.md)
│   └── nginx/                    # Webserver image + site configs (see ci-cd.md)
├── Dockerfile                    # Builder image: node:22-bookworm-slim + Chromium
├── docker-compose.yml            # Services: app-builder, webserver, certbot
├── Makefile                      # Dev, build, and deploy commands
├── package.json                  # npm scripts + dependencies
└── .github/workflows/
    └── superlinter.yml           # CI: lint on push / PR
```

`dist/` is the build output and is gitignored — never edit it by hand.

## Build pipeline

The whole build is `src/build.js`, run via `node src/build.js` (wrapped by `npm run build` and
`make page`). In order, it:

1. **Empties `dist/`** — `fs.emptyDirSync(outputDir)` (`outputDir` = `<repo>/dist`).
2. **Copies assets** — `src/assets/` → `dist/` verbatim (styles, photo, favicons, QR code).
3. **Registers the `markdown` helper** so templates can render Markdown content fields to HTML.
4. **Compiles the template** — reads `src/templates/index.html`, compiles it with Handlebars, and
   renders it with the data from `src/metadata/metadata.js` plus three injected values:
   - `baseUrl` — `https://valerio.dev`
   - `pdfFileName` — slugified `"<name>.<title>.pdf"` (via `speakingurl`)
   - `updated` — today's date, formatted with `dayjs` (`MMMM D, YYYY`)
5. **Writes `dist/index.html`**.
6. **Generates the PDF** — `src/utils/pdf.js` launches headless Chrome (Puppeteer), loads the
   freshly written `dist/index.html` as a `file://` URL (waiting for `networkidle0`), and prints
   an **A4** PDF with **2.54 cm** margins to `dist/<pdfFileName>`.

```text
metadata.js ─┐
             ├─▶ Handlebars ─▶ dist/index.html ─▶ Puppeteer ─▶ dist/<name>.<title>.pdf
index.html ──┘                      ▲
                                src/assets/ (copied into dist/)
```

Because the PDF is rendered from the same HTML, the HTML and PDF versions stay consistent by
construction. The CSS uses `screen` / `print` classes to vary output: the on-screen page shows a
"Download PDF" link, while the print/PDF version shows a QR code to the site instead
(`src/templates/index.html`).

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
  External assets are loaded from CDNs at runtime: Bootstrap 5.2, Font Awesome 6.1, and the
  Roboto Google Font.
- Sections rendered: header (photo + name + facts + PDF/QR), About me, Skills (bar chart),
  Professional Experience, Additional Experience, Robotics Competitions. Lists use Handlebars
  `{{#each}}` over the arrays above.
- `src/assets/styles.css` holds project-specific styling on top of Bootstrap, including the
  `screen` / `print` visibility rules and the skill-bar styling.
- Note: this template/repo originates from the [`sneas/cv-template`](https://github.com/sneas/cv-template)
  project (see the commented-out section in the root README).

## Runtime & dependencies

- Local builds use your system Node.js. The **Docker** builder image is based on
  `node:22-bookworm-slim` and installs the distro **Chromium** (used by Puppeteer via
  `PUPPETEER_EXECUTABLE_PATH`, with `PUPPETEER_SKIP_DOWNLOAD=true`) plus Latin/CJK fonts so
  Puppeteer can render the PDF inside the container (`Dockerfile`).
- Key npm dependencies (`package.json`): `handlebars` (templating), `puppeteer` (PDF),
  `fs-extra` (file ops), `dayjs` (dates), `speakingurl` (slugs), `markdown` (Markdown→HTML),
  plus dev tooling: `live-server` + `chokidar-cli`/`watch` (dev server), `stylelint`, and
  `gh-pages`.

For how the built site is served and deployed, see [ci-cd.md](ci-cd.md).

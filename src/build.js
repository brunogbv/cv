const handlebars = require('handlebars')
const fs = require('fs-extra')
const markdownHelper = require('./utils/helpers/markdown')
const templateData = require('./metadata/metadata')
const getSlug = require('speakingurl')
const dayjs = require('dayjs')
const dayjsUtc = require('dayjs/plugin/utc')
const buildPdf = require('./utils/pdf.js')
const path = require('path')

dayjs.extend(dayjsUtc)

const srcDir = __dirname
const outputDir = path.join(__dirname, '/../dist')
const nodeModules = path.join(__dirname, '/../node_modules')

// Build date. Honours SOURCE_DATE_EPOCH (the reproducible-builds convention: seconds since the Unix
// epoch) so a build can be made deterministic — the visual gate sets it so the PDF's "Last update"
// text is stable day-to-day (the screen snapshots instead hide that <time> via tests/snapshot.css,
// but the PDF is a fixed render that bakes it in). Unset (normal builds) it's today's date, as before.
// The pinned date is formatted in UTC so it's independent of the runtime's timezone — a fixed epoch
// must render the same calendar day everywhere, or the PDF's date text (and its wrapped layout)
// would drift and break the exact-match gate on a non-UTC host.
const epoch = process.env.SOURCE_DATE_EPOCH
let buildDate = dayjs()
if (epoch) {
  const seconds = Number(epoch)
  if (!Number.isFinite(seconds)) {
    throw new Error(`SOURCE_DATE_EPOCH must be a number (Unix seconds); got: ${JSON.stringify(epoch)}`)
  }
  buildDate = dayjs.unix(seconds).utc()
}

// Vendored CSS/fonts copied from pinned node_modules into dist/ so the page and PDF render with no
// third-party CDN at build/render time (issue #24). [from, to-relative-to-dist]
const vendoredAssets = [
  ['bootstrap/dist/css/bootstrap.min.css', 'vendor/bootstrap/bootstrap.min.css'],
  ['@fortawesome/fontawesome-free/css/all.min.css', 'vendor/fontawesome/css/all.min.css'],
  ['@fortawesome/fontawesome-free/webfonts', 'vendor/fontawesome/webfonts'],
  ['@fontsource/roboto/latin-400.css', 'vendor/roboto/latin-400.css'],
  ['@fontsource/roboto/latin-500.css', 'vendor/roboto/latin-500.css'],
  ['@fontsource/roboto/files/roboto-latin-400-normal.woff2', 'vendor/roboto/files/roboto-latin-400-normal.woff2'],
  ['@fontsource/roboto/files/roboto-latin-400-normal.woff', 'vendor/roboto/files/roboto-latin-400-normal.woff'],
  ['@fontsource/roboto/files/roboto-latin-500-normal.woff2', 'vendor/roboto/files/roboto-latin-500-normal.woff2'],
  ['@fontsource/roboto/files/roboto-latin-500-normal.woff', 'vendor/roboto/files/roboto-latin-500-normal.woff'],
  ['@fontsource-variable/fraunces/opsz.css', 'vendor/fraunces/opsz.css'],
  ['@fontsource-variable/fraunces/files/fraunces-latin-opsz-normal.woff2', 'vendor/fraunces/files/fraunces-latin-opsz-normal.woff2'],
  ['@fontsource-variable/fraunces/files/fraunces-latin-ext-opsz-normal.woff2', 'vendor/fraunces/files/fraunces-latin-ext-opsz-normal.woff2'],
  ['@fontsource-variable/fraunces/files/fraunces-vietnamese-opsz-normal.woff2', 'vendor/fraunces/files/fraunces-vietnamese-opsz-normal.woff2'],
  ['@fontsource-variable/spline-sans/wght.css', 'vendor/spline-sans/wght.css'],
  ['@fontsource-variable/spline-sans/files/spline-sans-latin-wght-normal.woff2', 'vendor/spline-sans/files/spline-sans-latin-wght-normal.woff2'],
  ['@fontsource-variable/spline-sans/files/spline-sans-latin-ext-wght-normal.woff2', 'vendor/spline-sans/files/spline-sans-latin-ext-wght-normal.woff2']
]

async function build () {
  // Clear dist dir
  fs.emptyDirSync(outputDir)

  // Copy assets
  fs.copySync(srcDir + '/assets', outputDir)

  // Copy vendored CSS/fonts from node_modules (fail loudly if a pinned dependency is missing)
  for (const [from, to] of vendoredAssets) {
    fs.copySync(path.join(nodeModules, from), path.join(outputDir, to))
  }

  // Build HTML
  handlebars.registerHelper('markdown', markdownHelper)
  const source = fs.readFileSync(srcDir + '/templates/index.html', 'utf-8')
  const template = handlebars.compile(source)
  const pdfFileName = `${getSlug(templateData.name)}.${getSlug(templateData.title)}.pdf`
  const html = template({
    ...templateData,
    baseUrl: 'https://valerio.dev',
    pdfFileName,
    updated: buildDate.format('MMMM D, YYYY')
  })

  fs.writeFileSync(outputDir + '/index.html', html)

  // Build PDF (awaited so a render failure aborts the build)
  await buildPdf(`${outputDir}/index.html`, `${outputDir}/${pdfFileName}`)
}

build().catch((err) => {
  console.error(err)
  process.exit(1)
})

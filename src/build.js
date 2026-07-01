const handlebars = require('handlebars')
const fs = require('fs-extra')
const markdownHelper = require('./utils/helpers/markdown')
const templateData = require('./metadata/metadata')
const getSlug = require('speakingurl')
const dayjs = require('dayjs')
// const repoName = require('git-repo-name')
// const username = require('git-username')
const buildPdf = require('./utils/pdf.js')
const path = require('path')

const srcDir = __dirname
const outputDir = path.join(__dirname, '/../dist')
const nodeModules = path.join(__dirname, '/../node_modules')

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
  ['@fontsource/roboto/files/roboto-latin-500-normal.woff', 'vendor/roboto/files/roboto-latin-500-normal.woff']
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
    updated: dayjs().format('MMMM D, YYYY')
  })

  fs.writeFileSync(outputDir + '/index.html', html)

  // Build PDF (awaited so a render failure aborts the build)
  await buildPdf(`${outputDir}/index.html`, `${outputDir}/${pdfFileName}`)
}

build().catch((err) => {
  console.error(err)
  process.exit(1)
})

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

// Clear dist dir
fs.emptyDirSync(outputDir)

// Copy assets
fs.copySync(srcDir + '/assets', outputDir)

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

// Build PDF
buildPdf(`${outputDir}/index.html`, `${outputDir}/${pdfFileName}`)

const { chromium } = require('playwright')

module.exports = async function buildPdf (inputFile, outputFile) {
  const browser = await chromium.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  })
  const page = await browser.newPage()
  await page.goto(`file://${inputFile}`, {
    waitUntil: 'networkidle'
  })
  await page.pdf({
    path: outputFile,
    format: 'A4',
    margin: {
      top: '2.54cm',
      right: '2.54cm',
      bottom: '2.54cm',
      left: '2.54cm'
    }
  })
  await browser.close()
}
